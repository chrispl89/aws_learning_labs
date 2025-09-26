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

### Day 4 – Backup / Storage / Monitoring
- Refactored Terraform code:
- Created full AWS environment:
  - **VPC** with public subnet
  - **Internet Gateway** and custom route table
  - **Security Group** with SSH (restricted to my IP) and HTTP (open)
  - **EC2 Instance** (Ubuntu 22.04, `t3.micro`)
- Provisioned **Flask web app** automatically via `user_data`:
  - Installed Python3 + Flask
  - Deployed simple app returning `Hello from AWS Flask app! 🚀`
  - Served directly on port **80**
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

### Day 7
- Refactored infrastructure into **Terraform modules**:
  - `network`, `security`, `compute`, `alb`
- Cleaner and reusable structure for future environments
- Additional tests:
  - SG rule validation (App SG allows 80 only from ALB SG)
  - IMDSv2 enforcement check
  - ALB → TG → EC2 health validation

### Day 8
- Added **S3 bucket** for static website hosting
- Fronted by **CloudFront** for CDN distribution
- Direct S3 access blocked (returns 403), site accessible only via CloudFront
- Test script checks:
  - CloudFront returns 200 on index.html
  - S3 URL returns 403 AccessDenied

### Day 9
- Added **RDS (PostgreSQL)** in public subnets (lab exercise, later to be moved to private)
- RDS SG allows DB port (5432) **only from App SG**
- Connected via EC2 (installed `postgresql-client`) and verified queries
- Automated validation:
  - RDS instance details (status, engine, version, VPC, public=false)
  - ALB target group health
  - SG rule check (App SG ingress from ALB SG)
- Manual test: insert + select from `health` table to confirm DB works
---

## 🔧 Tools & Technologies

- Core AWS services used so far:

  - IAM (credentials/profiles)

  - VPC (subnets, IGW, routes)

  - Security Groups

  - EC2 (Ubuntu), cloud-init/user_data, IMDSv2

  - ALB / Target Groups / Health checks

  - S3 (static site)

  - CloudFront (CDN in front of S3)

  - RDS PostgreSQL

- Terraform: for Infrastructure as Code

- PowerShell: local automation & testing

- GitHub Actions: CI for Terraform formats & validation

- Pre-commit: local quality checks (format, validate, lint)

---

## 📌 Current status

- Completed: Days 1 → 9, each with its own Terraform stack (kept intact to show evolution).

- Pre-commit: enabled; commits run fmt/validate/tflint + whitespace fixers.

- CI: GitHub Actions workflow validates Terraform on push.

- Security posture (current lab scope):

  - EC2 HTTP reachable only through ALB.

  - SSH restricted to my_ip (/32).

  - IMDSv2 enforced on EC2.

  - RDS reachable only from App SG; not publicly accessible.

  - CloudFront in front of S3 (origin access locked).

### Next milestones (upcoming days):

  - Move RDS to private subnets (+ NAT).

  - Store secrets in Secrets Manager/SSM (no plain tfvars).

  - Replace Nginx with a simple app connecting to Postgres (health tied to DB).

  - Add autoscaling/observability and polish CI.

---

📌 This repo will serve both as a **learning diary** and as a **portfolio** to showcase AWS/DevOps skills.
