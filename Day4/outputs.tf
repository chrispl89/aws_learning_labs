output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.lab_ec2.public_ip
}

output "flask_url" {
  description = "Flask app URL"
  value       = "http://${aws_instance.lab_ec2.public_ip}"
}
