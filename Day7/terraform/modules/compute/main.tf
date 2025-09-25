resource "aws_instance" "app" {
  count                       = var.instance_count
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.app_sg_id]
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true

  metadata_options {
    http_tokens = "required"
  }

  # ensure recreation when user_data changes
  user_data_replace_on_change = true

  user_data = <<EOF
#!/bin/bash
set -eux
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx
echo "Hello from $(hostname -f)" > /var/www/html/index.html
systemctl enable nginx
systemctl restart nginx
EOF

  tags = merge(var.common_tags, { Name = "${var.name_prefix}-ec2-${count.index + 1}" })
}

output "instance_ids" {
  value = aws_instance.app[*].id
}

output "instance_public_ips" {
  value = aws_instance.app[*].public_ip
}
