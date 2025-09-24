# 1. VPC
resource "aws_vpc" "lab_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "lab-vpc" }
}

# 2. Public subnet
resource "aws_subnet" "lab_subnet" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone

  tags = { Name = "lab-subnet" }
}

# 2b. Public subnet 2
resource "aws_subnet" "lab_subnet_b" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1b"

  tags = { Name = "lab-subnet-b" }
}


# 3. Internet Gateway
resource "aws_internet_gateway" "lab_igw" {
  vpc_id = aws_vpc.lab_vpc.id
  tags   = { Name = "lab-igw" }
}

# 4. Route Table + default route
resource "aws_route_table" "lab_rtb" {
  vpc_id = aws_vpc.lab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab_igw.id
  }

  tags = { Name = "lab-rtb" }
}

resource "aws_route_table_association" "lab_rtb_assoc" {
  subnet_id      = aws_subnet.lab_subnet.id
  route_table_id = aws_route_table.lab_rtb.id
}

# 5. Security Group (SSH + HTTP)
resource "aws_security_group" "lab_sg" {
  vpc_id = aws_vpc.lab_vpc.id
  name   = "lab-sg"

  ingress {
    description = "Allow SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "Allow HTTP (Flask/NGINX) from all"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "lab-sg" }
}

# 6. EC2 Instances (count)
resource "aws_instance" "lab_ec2" {
  count                       = var.instance_count
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.lab_subnet.id
  vpc_security_group_ids      = [aws_security_group.lab_sg.id]
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y python3 python3-pip
              pip3 install flask
              cat <<EOT > /home/ubuntu/app.py
              from flask import Flask
              app = Flask(__name__)
              @app.route('/')
              def hello():
                  return "Hello from AWS Flask app! 🚀 (Instance: $(hostname))"
              if __name__ == "__main__":
                  app.run(host="0.0.0.0", port=${var.app_port})
              EOT
              nohup python3 /home/ubuntu/app.py &
              EOF

  tags = { Name = "lab-ec2-${count.index}" }
}

# 7. Target Group
resource "aws_lb_target_group" "lab_tg" {
  name     = var.target_group_name
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.lab_vpc.id

  health_check {
    path                = "/"
    port                = var.app_port
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = { Name = var.target_group_name }
}

# 8. Register EC2 Instances in TG
resource "aws_lb_target_group_attachment" "lab_tg_attachment" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.lab_tg.arn
  target_id        = aws_instance.lab_ec2[count.index].id
  port             = var.app_port
}

# 9. Application Load Balancer
resource "aws_lb" "lab_alb" {
  name               = var.alb_name
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lab_sg.id]
  subnets = [
    aws_subnet.lab_subnet.id,
    aws_subnet.lab_subnet_b.id
  ]

  tags = { Name = var.alb_name }
}

# 10. Listener for ALB
resource "aws_lb_listener" "lab_alb_listener" {
  load_balancer_arn = aws_lb.lab_alb.arn
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lab_tg.arn
  }
}
