variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "eu-north-1a"
}

variable "my_ip" {
  description = "Publiczny IP do SSH"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of key pair in AWS"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI for EC2 instance"
  type        = string
  default     = "ami-0068163775a114e89"
}

# How many EC2 instances to run
variable "instance_count" {
  description = "Number of EC2 instances"
  type        = number
  default     = 2
}

# Port on which the application runs (Flask/NGINX)
variable "app_port" {
  description = "Application port"
  type        = number
  default     = 80
}

variable "alb_name" {
  description = "Name for the Application Load Balancer"
  type        = string
  default     = "lab-alb"
}

variable "target_group_name" {
  description = "Target group name"
  type        = string
  default     = "lab-tg"
}

