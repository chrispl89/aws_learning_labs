# 1. VPC
resource "aws_vpc" "lab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "lab-vpc" }
}

# 2. Subnet publiczny
resource "aws_subnet" "lab_subnet" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1a"

  tags = { Name = "lab-subnet" }
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

  tags = { Name = "lab-sg" }
}

# 6. EC2 Instance z Flask
resource "aws_instance" "lab_ec2" {
  ami                         = "ami-0068163775a114e89"
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.lab_subnet.id
  vpc_security_group_ids      = [aws_security_group.lab_sg.id]
  key_name                    = "krzysztof-key"
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
                  return "Hello from AWS Flask app! 🚀"
              if __name__ == "__main__":
                  app.run(host="0.0.0.0", port=80)
              EOT
              nohup python3 /home/ubuntu/app.py &
              EOF

  tags = { Name = "lab-ec2" }
}
