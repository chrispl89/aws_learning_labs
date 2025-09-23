output "ec2_ids" {
  description = "IDs of the EC2 instances"
  value       = [for i in aws_instance.lab_ec2 : i.id]
}

output "ec2_public_ips" {
  description = "Public IPs of the EC2 instances"
  value       = [for i in aws_instance.lab_ec2 : i.public_ip]
}

output "flask_urls" {
  description = "Direct Flask URLs (not via ALB)"
  value       = [for i in aws_instance.lab_ec2 : "http://${i.public_ip}"]
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.lab_vpc.id
}

output "subnet_ids" {
  description = "IDs of the public subnets"
  value       = [aws_subnet.lab_subnet.id, aws_subnet.lab_subnet_b.id]
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.lab_sg.id
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.lab_alb.dns_name
}

output "alb_url" {
  description = "HTTP URL of the ALB"
  value       = "http://${aws_lb.lab_alb.dns_name}"
}
