# Provider AWS
provider "aws" {
  region  = "eu-north-1"
  profile = "krzysztof-admin"
}

# 1. VPC
resource "aws_vpc" "lab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "lab-vpc"
  }
}

# 2. Subnet publiczny
resource "aws_subnet" "lab_subnet" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1a"

  tags = {
    Name = "lab-subnet"
  }
}

# 3. Internet Gateway
resource "aws_internet_gateway" "lab_igw" {
  vpc_id = aws_vpc.lab_vpc.id

  tags = {
    Name = "lab-igw"
  }
}

# 4. Route Table + default route
resource "aws_route_table" "lab_rtb" {
  vpc_id = aws_vpc.lab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab_igw.id
  }

  tags = {
    Name = "lab-rtb"
  }
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
    cidr_blocks = ["185.241.199.206/32"] # Twój publiczny IP
  }

  ingress {
    description = "Allow HTTP from all"
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

  tags = {
    Name = "lab-sg"
  }
}




# 6. EC2 Instance
resource "aws_instance" "lab_ec2" {
  ami                         = "ami-0068163775a114e89"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.lab_subnet.id
  vpc_security_group_ids      = [aws_security_group.lab_sg.id]
  key_name                    = "krzysztof-key"
  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

    user_data = <<EOF
#!/bin/bash
echo "TEST USER DATA" > /tmp/test.txt
apt-get update -y
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx
EOF

  tags = {
    Name = "lab-ec2"
  }
}



