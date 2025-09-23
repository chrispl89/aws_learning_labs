# Day 4 – AWS Lab with Terraform & Flask App

## What was done
- Refactored Terraform code:
  - separated into `main.tf`, `provider.tf`, `variables.tf`, `outputs.tf`
  - introduced variables for EC2 instance type and allowed IP
  - added outputs for public IP and Flask app URL
- Created full AWS environment:
  - **VPC** with public subnet
  - **Internet Gateway** and custom route table
  - **Security Group** with SSH (restricted to my IP) and HTTP (open)
  - **EC2 Instance** (Ubuntu 22.04, `t3.micro`)
- Provisioned **Flask web app** automatically via `user_data`:
  - Installed Python3 + Flask
  - Deployed simple app returning `Hello from AWS Flask app! 🚀`
  - Served directly on port **80**

## Outputs
Example after `terraform apply`:

`ec2_public_ip = "13.60.72.71"`

`flask_url = "http://13.60.72.71"`

## Verification
Check the app in a browser:
`http://<ec2_public_ip>`

You should see:

`Hello from AWS Flask app! 🚀`

## Next steps
- Experiment with variables and reusability
- Deploy multiple instances behind a load balancer
- Explore Terraform modules for cleaner code
