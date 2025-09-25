# Day 7 – Modularization of Infrastructure

In this lab I refactored the Day 6 configuration into **Terraform modules** to improve readability, reusability, and maintainability.

---

## What changed vs Day 6?

- **Modules introduced**:
  - `network` – VPC, subnets, route tables, IGW
  - `security` – ALB SG, App SG, SG rules
  - `compute` – EC2 instances with `user_data` (Nginx, IMDSv2 enforced)
  - `alb` – Application Load Balancer, Target Group, Listener
- **Variables cleaned up** – all centralized in `variables.tf`
- **Environments** – still use `envs/dev.tfvars`, `envs/stage.tfvars`
- **Outputs** – ALB DNS, ALB URL, EC2 public IPs
- **Tests** – enhanced `test.ps1` validates:
  - ALB HTTP (200 from all requests)
  - EC2 hardened (HTTP blocked from the Internet)
  - SSH access restricted to your IP
  - ALB spread across 2 AZs
  - IMDSv2 required on all EC2s
  - App port allowed **only** from ALB SG

---

## Usage

### Init
```powershell
cd Day7/terraform
terraform init
```
### Plan
```powershell
terraform plan -var-file="envs/dev.tfvars"
```

### Apply
```powershell
terraform apply -var-file="envs/dev.tfvars"
```

### Destroy
```powershell
terraform destroy -var-file="envs/dev.tfvars"
```
### Testing

Run the test script after deployment:
```powershell
cd Day7/terraform
$env:AWS_PROFILE = "krzysztof-admin"
$env:AWS_REGION  = "eu-north-1"
powershell -ExecutionPolicy Bypass -File .\test.ps1
```

Expected results:

✅ ALB responds with 200

✅ EC2 not accessible directly on port 80

✅ EC2 SSH accessible only from your IP (/32)

✅ Targets healthy in TG

✅ IMDSv2 = required

✅ ALB spans two AZs

✅ SG rules: App port allowed only from ALB SG

## Key Learnings

Breaking down monolithic Terraform into modules makes infrastructure easier to manage.

Security best practices are preserved: SG hardening, IMDSv2, restricted SSH.

Testing automation via test.ps1 ensures the infra works as expected after each change.
