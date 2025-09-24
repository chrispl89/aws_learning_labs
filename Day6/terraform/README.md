# Day 6 – Application Load Balancer with Hardened Security Groups

## Goal
Deploy a highly available setup with:
- **VPC** and **two public subnets** (different AZs)
- **Application Load Balancer (ALB)**
- **Target Group with EC2 instances**
- **Hardened Security Groups**:
  - ALB SG: allows inbound HTTP (80) from the Internet
  - App SG: allows SSH (22) only from your `/32`
  - App SG: allows HTTP only from ALB SG
- **EC2 instances**:
  - Ubuntu AMI
  - Enforce IMDSv2
  - Install and run Nginx via `user_data`
  - Auto-recreated if `user_data` changes
- **Terraform improvements**:
  - `user_data_replace_on_change`
  - `http` data source to auto-detect your public IP
  - Separate `dev.tfvars` and `stage.tfvars` environments
  - CI with GitHub Actions and pre-commit hooks

---

## Usage

### Init & plan
```bash
cd Day6/terraform
terraform init
terraform plan -var-file="envs/dev.tfvars"
```
### Apply
``` bash
terraform apply -var-file="envs/dev.tfvars"
```
### Outputs

After apply, you get:
```bash
alb_dns_name

alb_url

ec2_public_ips
```
### Testing
A helper script is included:

```powershell
$env:AWS_PROFILE = "your-profile"
$env:AWS_REGION  = "eu-north-1"
powershell -ExecutionPolicy Bypass -File .\Day6\terraform\test.ps1
```
What it does:

- Reads Terraform outputs

- Sends 10 requests to ALB → expect HTTP 200

- Verifies that direct HTTP to EC2 is blocked

- Verifies SSH:22 access (open only from your /32)

- Prints Target Group health from AWS CLI

Example output
```sql
==> Reading Terraform outputs...
ALB: http://aws-lab-dev-lab-alb-1593190730.eu-north-1.elb.amazonaws.com
ALB DNS: aws-lab-dev-lab-alb-1593190730.eu-north-1.elb.amazonaws.com
EC2 IPs: 51.20.43.87, 13.53.170.60

==> Hitting ALB 10 times (show HTTP codes/errors)...
Try Code
--- ----
1   200
2   200
...
10  200
OK: all returned 200

==> Verifying SG hardening...
OK: HTTP:80 blocked for direct EC2 access
OK: SSH:22 reachable (from your IP)

==> Target health:
+----------------------+-------+-----------+
| Instance             | Port  | State     |
+----------------------+-------+-----------+
| i-000c0f9b6c64c5712  | 80    | healthy   |
| i-01545de93216e3ee8  | 80    | healthy   |
+----------------------+-------+-----------+
```
## Cleanup
To avoid costs:

```bash
terraform destroy -var-file="envs/dev.tfvars"
```
## Key Learnings
- How to design SGs for ALB + EC2 separation

- Using Terraform http data source to auto-detect caller IP

- Enforcing IMDSv2 on EC2

- Using user_data_replace_on_change for consistent provisioning

- Validating infra with PowerShell test script

- GitHub Actions CI for Terraform validate/fmt

- Pre-commit hooks (tflint, fmt, validate, whitespace fixes)
