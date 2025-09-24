########################################
# Resolve caller's public IPv4 (for SSH allowlist)
########################################
data "http" "me" {
  url = "https://checkip.amazonaws.com/"
}

########################################
# Locals
########################################
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = "Krzysztof"
    ManagedBy   = "Terraform"
  }

  name_prefix = "${var.project}-${var.environment}"

  # If my_ip is provided, use it; otherwise auto-detect and append /32
  effective_my_ip = (
    var.my_ip != null && var.my_ip != "" ?
    var.my_ip :
    "${chomp(data.http.me.response_body)}/32"
  )
}

########################################
# Network: VPC, Public Subnets, IGW, Routes
########################################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-vpc" })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-subnet-public-a" })
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr_b
  availability_zone       = var.availability_zone_b
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-subnet-public-b" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-igw" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-rt-public" })
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc_a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_assoc_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

########################################
# Security Groups
########################################

# ALB SG: allow HTTP from the Internet
resource "aws_security_group" "alb_sg" {
  name        = "${local.name_prefix}-sg-alb"
  description = "Allow HTTP from the Internet to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-sg-alb" })
}

# App SG: SSH only from your IP; HTTP only from ALB SG
resource "aws_security_group" "app_sg" {
  name        = "${local.name_prefix}-sg-app"
  description = "Allow SSH from my IP; HTTP only from ALB"
  vpc_id      = aws_vpc.main.id

  # SSH from your /32
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.effective_my_ip]
  }

  # Default egress to the Internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-sg-app" })
}

# Ingress rule: App port only from ALB SG
resource "aws_security_group_rule" "app_from_alb" {
  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

########################################
# Compute: EC2 instances
########################################
resource "aws_instance" "app" {
  count                       = var.instance_count
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true

  # Enforce IMDSv2 for instance metadata access
  metadata_options {
    http_tokens = "required"
  }

  # Always recreate instance when user_data changes
  user_data_replace_on_change = true

  # Ubuntu-focused, simple and robust user_data (no indentation, no tabs)
  user_data = <<EOF
#!/bin/bash
set -eux

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y nginx

echo "Hello from $(hostname -f)" > /var/www/html/index.html

systemctl enable nginx
systemctl restart nginx
EOF

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-${count.index + 1}"
  })
}

########################################
# Load Balancing: Target Group, Attachments, ALB, Listener
########################################
resource "aws_lb_target_group" "tg" {
  name     = "${local.name_prefix}-${var.target_group_name}"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-tg" })
}

resource "aws_lb_target_group_attachment" "att" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.app[count.index].id
  port             = var.app_port
}

resource "aws_lb" "alb" {
  name               = "${local.name_prefix}-${var.alb_name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_b.id]

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-alb" })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
