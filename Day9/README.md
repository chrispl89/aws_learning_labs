# Day 9 – RDS (Relational Database Service) Integration

## 🎯 Goal
- Extend our infrastructure with a **PostgreSQL RDS instance**.
- Enforce **secure connectivity**: database is **not publicly accessible**, only EC2 instances (App SG) can reach it.
- Understand how **ALB health checks** and **security groups** influence service availability.

---

## 🏗️ What we built

### 1. Network & Security
- VPC with two public subnets (reused from Day 7).
- **App SG**:
  - SSH (22) allowed only from `my_ip`.
  - HTTP (80) allowed only from **ALB SG**.
- **ALB SG**:
  - HTTP (80) allowed from `0.0.0.0/0`.
- **RDS SG**:
  - PostgreSQL port (5432) allowed only from **App SG**.

### 2. Compute (EC2)
- 2x Ubuntu EC2 instances with **Nginx** installed via `user_data`.
- Simple HTML page served: `"Hello from $(hostname)"`.
- Instances registered in ALB Target Group.

### 3. RDS (Postgres)
- **DB subnet group** created across Subnet A + B.
- RDS instance (`db.t3.micro`):
  - Engine: `postgres`, version `15.8`.
  - User: `dbmaster` (we couldn’t use `admin` → reserved).
  - Password stored in `tfvars`.
  - Endpoint example:
    ```
    aws-lab-dev-db.ctauy6ko6u97.eu-north-1.rds.amazonaws.com:5432
    ```
  - Not publicly accessible.

### 4. Testing & Debugging
- At first, ALB targets were `unhealthy` (`Target.Timeout`).
- Root cause: missing SG rule from ALB SG → App SG.
- Temporary test with `0.0.0.0/0` fixed it (healthy), then restored **correct rule** (`ALB SG → App SG`).
- Final checks:
  - ✅ ALB returns HTTP 200
  - ✅ EC2 accessible via ALB only
  - ✅ RDS reachable from EC2 using `psql` client

Example query from EC2:
```sql
psql -h <db_endpoint> -U dbmaster -d postgres -p 5432
```
✅ Final outcome

- Complete stack:

    - VPC + subnets + IGW + route tables

    - ALB with Target Group

    - EC2 app servers with Nginx

    - RDS Postgres secured to App SG only

Learned:

- How ALB health checks depend on app + SGs

- How to configure least privilege access for RDS

- How to connect to RDS from EC2 and run SQL queries
