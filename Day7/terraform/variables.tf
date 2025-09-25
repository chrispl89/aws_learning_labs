########################################
# Global
########################################

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

########################################
# Networking
########################################

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "subnet_cidr_b" {
  type    = string
  default = "10.0.2.0/24"
}

variable "availability_zone" {
  type    = string
  default = "eu-north-1a"
}

variable "availability_zone_b" {
  type    = string
  default = "eu-north-1b"
}

########################################
# Compute / App
########################################

variable "my_ip" {
  type    = string
  default = null
  description = "If null/empty, security module will auto-detect caller IP and append /32."
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

########################################
# ALB
########################################

variable "alb_name" {
  type    = string
  default = "lab-alb"
}

variable "target_group_name" {
  type    = string
  default = "lab-tg"
}
