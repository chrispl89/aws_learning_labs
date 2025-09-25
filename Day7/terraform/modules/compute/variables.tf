variable "vpc_id" {}
variable "subnet_id" {}
variable "ssh_key_name" {}
variable "ami_id" {}
variable "instance_type" {}
variable "instance_count" {}
variable "app_port" {}
variable "app_sg_id" {}
variable "name_prefix" {}
variable "common_tags" { type = map(string) }
