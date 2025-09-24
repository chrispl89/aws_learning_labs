########################################
# Global / meta
########################################

variable "project" {
  description = "Project tag/prefix used in resource names and tags."
  type        = string
  default     = "aws-lab"
}

variable "environment" {
  description = "Environment identifier (e.g., dev, stage, prod)."
  type        = string
  default     = "dev"
}

variable "aws_profile" {
  description = "AWS CLI profile to use for the provider."
  type        = string
  default     = "krzysztof-admin"
}

variable "aws_region" {
  description = "AWS region to deploy resources in."
  type        = string
  default     = "eu-north-1"
}

########################################
# Networking
########################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the first public subnet (AZ A)."
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_cidr_b" {
  description = "CIDR block for the second public subnet (AZ B)."
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "Primary availability zone (e.g., eu-north-1a)."
  type        = string
  default     = "eu-north-1a"
}

variable "availability_zone_b" {
  description = "Secondary availability zone (e.g., eu-north-1b)."
  type        = string
  default     = "eu-north-1b"
}

########################################
# Access / compute
########################################

variable "my_ip" {
  description = "Your public IPv4 in CIDR to allow SSH (e.g., 203.0.113.10/32). If null/empty, it will be auto-detected."
  type        = string
  default     = null

  validation {
    condition     = var.my_ip == null || var.my_ip == "" || can(regex("^\\d{1,3}(?:\\.\\d{1,3}){3}/\\d{1,2}$", var.my_ip))
    error_message = "my_ip must be null/empty (for auto-detect) or an IPv4 CIDR like 203.0.113.10/32."
  }
}

variable "ssh_key_name" {
  description = "Existing AWS key pair name to associate with EC2 instances."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances."
  type        = string
  default     = "ami-0068163775a114e89"
}

variable "instance_count" {
  description = "Number of EC2 instances behind the ALB."
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "instance_count must be between 1 and 10."
  }
}

variable "app_port" {
  description = "Application port exposed by instances and the target group."
  type        = number
  default     = 80

  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "app_port must be between 1 and 65535."
  }
}

########################################
# Load balancer
########################################

variable "alb_name" {
  description = "Base name for the Application Load Balancer (will be prefixed)."
  type        = string
  default     = "lab-alb"
}

variable "target_group_name" {
  description = "Base name for the target group (will be prefixed)."
  type        = string
  default     = "lab-tg"
}
