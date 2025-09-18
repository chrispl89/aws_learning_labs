# Day 1 – IAM, MFA, Budgets, AWS CLI

## ✅ What I've done:
- Created IAM User `krzysztof-admin`
- Turned on MFA using Google Authenticator
- Activated IAM Access to Billing
- Created budget $1 with alert
- Configurated AWS CLI (profile `krzysztof-admin`)
- Created test bucket S3

## 🔍 `aws sts get-caller-identity` result:
{
    "UserId": "AIDATYNW6B4MQSA6GMJNF",
    "Account": "258618560281",
    "Arn": "arn:aws:iam::258618560281:user/krzysztof-admin"
}

## 🪣  `aws s3 ls` result:
2025-09-17 09:05:50 krzysztof-aws-lab-2025
