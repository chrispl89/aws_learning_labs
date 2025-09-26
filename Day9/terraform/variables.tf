# Global / tags / env
variable "project" {
  type    = string
  default = "aws-lab"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_profile" {
  type    = string
  default = "krzysztof-admin"
}

variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

# Network
variable "vpc_cidr" {
  type    = string
  default = "10.9.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.9.1.0/24"
}

variable "subnet_cidr_b" {
  type    = string
  default = "10.9.2.0/24"
}

variable "availability_zone" {
  type    = string
  default = "eu-north-1a"
}

variable "availability_zone_b" {
  type    = string
  default = "eu-north-1b"
}

# Access / app
variable "my_ip" {
  description = "Your public IP in CIDR (/32). Leave empty to auto-detect."
  type        = string
  default     = ""
}

variable "ssh_key_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_id" {
  type    = string
  default = "ami-0068163775a114e89"
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "app_port" {
  type    = number
  default = 80
}

# ALB naming
variable "alb_name" {
  type    = string
  default = "lab-alb"
}

variable "target_group_name" {
  type    = string
  default = "lab-tg"
}

# RDS
variable "db_engine" {
  description = "postgres or mysql"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  type    = string
  default = "15.4"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_port" {
  type    = number
  default = 5432
}
