output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_url" {
  value = module.alb.alb_url
}

output "ec2_public_ips" {
  value = module.compute.instance_public_ips
}
