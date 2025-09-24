# AWS Learning Labs 🚀

This repository documents my step-by-step journey of learning **AWS, Terraform, and DevOps practices**.
The goal is to build a solid foundation in cloud, automation, and infrastructure-as-code while creating a practical portfolio.

---

## 📆 Learning Path

### Day 1 – AWS Account Setup
- Configured IAM user with MFA
- Enabled billing and cost management access
- Installed AWS CLI and verified configuration

### Day 2 – Networking Basics
- Created custom **VPC**
- Configured **Subnet**, **Route Table**, and **Internet Gateway**
- Defined **Security Group** with SSH and HTTP access rules
- Launched first **EC2 instance** manually

### Day 3 – Infrastructure as Code with Terraform
- Installed Terraform and initialized first configuration
- Automated deployment of:
  - VPC, Subnet, IGW, Route Table
  - Security Group (SSH only from my IP, HTTP for everyone)
  - EC2 instance (`t3.micro`) with nginx pre-installed via `user_data`
- Verified nginx page accessible via public IP

---

## 🛠️ Tools & Tech
- **AWS** (IAM, VPC, EC2, Billing)
- **Terraform** (Infrastructure as Code)
- **PowerShell** (automation on Windows)
- **GitHub** (portfolio building)

---

## 🔮 Next Steps
- Add automation for multiple environments (dev/stage/prod)
- Explore S3 + CloudFront
- Deploy a containerized app on ECS or EKS
- Implement monitoring and alerting

---

## ✅ Current Progress
- [x] Day 1 – AWS IAM & Billing
- [x] Day 2 – Networking + EC2 manually
- [x] Day 3 – Terraform automation with nginx
- [ ] Day 4 – TBD

---

📌 This repo will serve both as a **learning diary** and as a **portfolio** to showcase AWS/DevOps skills.
