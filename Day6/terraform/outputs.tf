output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "ALB DNS"
}

output "alb_url" {
  value       = "http://${aws_lb.alb.dns_name}"
  description = "ALB URL"
}

output "ec2_public_ips" {
  value       = [for i in aws_instance.app : i.public_ip]
  description = "Public IPs of EC2"
}
