variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "my_ip" {
  description = "Your public IP for SSH access"
  default     = "185.241.199.206/32"
}
