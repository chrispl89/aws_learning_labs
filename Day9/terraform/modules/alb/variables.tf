variable "vpc_id" {}
variable "subnet_ids" { type = list(string) }
variable "alb_sg_id" {}
variable "target_group_name" {}
variable "app_port" {}
variable "instance_ids" { type = list(string) }
variable "name_prefix" {}
variable "common_tags" { type = map(string) }
variable "alb_name" {}
