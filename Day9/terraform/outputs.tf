output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_url" {
  value = "http://${module.alb.alb_dns_name}"
}

output "ec2_public_ips" {
  value = module.compute.instance_public_ips
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.db.endpoint
}

output "db_port" {
  description = "RDS port"
  value       = aws_db_instance.db.port
}
