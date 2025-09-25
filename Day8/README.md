# Day 8 – Static Website on S3 + CloudFront (OAC)

## Goals
- Host a static website in **Amazon S3**, but keep the bucket **private**.
- Distribute content securely using **Amazon CloudFront** with an **Origin Access Control (OAC)**.
- Block direct access to S3, allowing access **only through CloudFront**.
- Automate provisioning and verification with Terraform + PowerShell tests.

---

## What we built
1. **S3 bucket**
   - Private (no public ACLs, no public bucket policy).
   - Static file (`index.html`) uploaded automatically via Terraform.

2. **CloudFront distribution**
   - Origin: S3 bucket (private).
   - **OAC (Origin Access Control)** → grants CloudFront permission to fetch from S3.
   - Default behavior: allow HTTP GET from anywhere.

3. **Bucket policy**
   - Grants `s3:GetObject` **only** to CloudFront via OAC.
   - Blocks all direct access.

4. **Terraform outputs**
   - `cloudfront_domain_name` – distribution DNS.
   - `s3_bucket_name` – private bucket name.
   - `site_url` – full URL to test website (`https://.../index.html`).

---

## Testing
Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\test.ps1
```

Expected results:

- CloudFront – 200 OK for multiple requests.

- Direct S3 URL – 403 Forbidden (blocked).

✅ Example run:
```yaml
CloudFront: d1xqudbeyk7zi7.cloudfront.net
S3 Bucket:  aws-lab-dev-static-site
Site URL:   https://d1xqudbeyk7zi7.cloudfront.net/index.html

==> GET CloudFront URL (expect 200)...
1 200
2 200
3 200
4 200
5 200
OK: all returned 200

==> Trying direct S3 URL (should be blocked: 403/AccessDenied)...
Got expected denial from S3. HTTP 403
```
Key Takeaways

- S3 bucket remains private → no direct object access.

- CloudFront + OAC is the modern, secure way to expose static S3 content.

- Caching & CDN – faster global delivery via CloudFront.

- This pattern is the best practice for static sites on AWS.
