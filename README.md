# AWS Learning Labs 🚀

This repository documents my step-by-step journey of learning **AWS, Terraform, and DevOps practices**.
The goal is to build a solid foundation in cloud, automation, and infrastructure-as-code while creating a practical portfolio.

---

## 🚀 Learning Path & Progress

### Day 1 – AWS Account & IAM Setup
- Created IAM user, configured MFA
- Enabled billing, cost monitoring
- Installed AWS CLI and tested access

### Day 2 – VPC & Networking Basics
- Built custom VPC
- Created Subnet, Route Table, Internet Gateway
- Set up Security Group with SSH + HTTP
- Launched first EC2 manually

### Day 3 – Terraform Intro & EC2 + NGINX
- Initialized Terraform
- Automated VPC, Subnet, SG, EC2
- Used `user_data` to install NGINX
- Verified web page accessible

### Day 4 – Backup / Storage / Monitoring (if done)
*(You can update this after you complete Day 4’s tasks)*

### Day 5 – ALB + Load Balancing
- Added ALB, Target Group, Listener
- Created multiple EC2 instances for distribution
- Verified round-robin routing

### Day 6 – Hardened ALB + EC2 Architecture (this day)
- Split into **two public subnets** across AZs
- Introduced **two Security Groups**:
  - ALB SG: HTTP from Internet
  - App SG: SSH only from your IP, HTTP only from ALB
- Enforced **IMDSv2** on EC2
- Wrote robust `user_data` that installs NGINX on Ubuntu
- Auto-detect your public IP for SSH
- Added test script (`test.ps1`) to validate functionality
- Integrated CI with GitHub Actions & pre-commit hooks


---

## 🔧 Tools & Technologies

- AWS: VPC, EC2, Load Balancer, IGW, SG

- Terraform: for Infrastructure as Code

- PowerShell: local automation & testing

- GitHub Actions: CI for Terraform formats & validation

- Pre-commit: local quality checks (format, validate, lint)

---

## 📌 Current Status & Next Steps
Day 6 is completed and verified.
What’s next:

- Refactor Day 6 into reusable Terraform modules (network, security, compute, ALB)

- Add day 7 labs: e.g. modules, RDS, autoscaling, S3, monitoring

- Enhance security (WAF, private subnets, bastion host)

- Add documentation and diagrams per day

---

📌 This repo will serve both as a **learning diary** and as a **portfolio** to showcase AWS/DevOps skills.
