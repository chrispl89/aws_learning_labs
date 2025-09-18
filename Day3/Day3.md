# Day 3 – AWS Lab with Terraform

## What was done
- Created custom **VPC** with public subnet
- Added **Internet Gateway** and default route
- Configured **Security Group**:
  - SSH only from my IP
  - HTTP for everyone
- Deployed **EC2 instance** (`t3.micro`) into the subnet
- Automated installation of **nginx** using `user_data`

## Outputs
- EC2 ID: `${ec2_id}`
- Public IP: `${ec2_public_ip}`
- NGINX URL: `${nginx_url}`

## Verification
After `terraform apply`, open the URL in your browser:

`http://<ec2_public_ip>`


You should see **"Welcome to nginx"** 🎉
