variable "project" {}
variable "environment" {}
variable "vpc_cidr" {}
variable "subnet_cidr" {}
variable "subnet_cidr_b" {}
variable "availability_zone" {}
variable "availability_zone_b" {}
variable "common_tags" { type = map(string) }
variable "name_prefix" { type = string }
