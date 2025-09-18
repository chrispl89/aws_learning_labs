output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.lab_ec2.public_ip
}

output "ec2_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.lab_ec2.id
}

output "nginx_url" {
  value = "http://${aws_instance.lab_ec2.public_ip}"
}
