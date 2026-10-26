# AWS Secure Cloud Infrastructure Automation

## Project Overview
This portfolio project demonstrates how to deploy and verify foundational AWS security controls using Terraform and the AWS CLI.

The goal is to apply infrastructure-as-code practices to build secure cloud resources in a repeatable, documented way.

## Architecture
- **Cloud provider:** Amazon Web Services (AWS)
- **Region:** US East (Ohio) — `us-east-2`
- **Infrastructure as Code:** Terraform
- **Storage:** Amazon S3
- **Verification:** AWS CLI
- **Version control:** Git and GitHub

## Security Controls Implemented

### 1. S3 Public Access Protection
Configured all four S3 Block Public Access settings to prevent public ACLs and public bucket policies from exposing the bucket.

### 2. Encryption at Rest
Configured default server-side encryption using Amazon S3-managed keys (SSE-S3, AES-256).

### 3. Bucket Versioning
Enabled S3 versioning to preserve previous object versions and support recovery from certain accidental changes or deletions.

### 4. Infrastructure as Code
Used Terraform to define, validate, plan, deploy, and manage the infrastructure.

## Repository Structure

```text
.
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── .terraform.lock.hcl
├── scripts/
├── .github/
├── .gitignore
└── README.md
```

## Deployment

Prerequisites:
- Terraform installed
- AWS CLI installed
- An AWS account with appropriate permissions
- AWS authentication configured locally

From the `terraform` directory, run:

```powershell
terraform init
terraform validate
terraform plan
terraform apply
```

Review the proposed changes before approving `terraform apply`. These commands can create real AWS resources and may incur charges.

## Security Verification

Run these AWS CLI commands to verify the deployed bucket configuration:

```powershell
aws s3api get-public-access-block --bucket aws-secure-cloud-portfolio-mh-2026

aws s3api get-bucket-encryption --bucket aws-secure-cloud-portfolio-mh-2026

aws s3api get-bucket-versioning --bucket aws-secure-cloud-portfolio-mh-2026
```

Expected results:
- All four public-access-block settings are `true`.
- Default server-side encryption uses `AES256`.
- Bucket versioning status is `Enabled`.

## Security and Cost Notes
- Terraform state files and local Terraform working directories are excluded from version control.
- Never commit AWS credentials, access keys, session tokens, or other secrets.
- AWS budgets and alerts help monitor costs but do not automatically stop all spending.
- S3 storage, requests, and retained object versions may incur charges.

## Future Enhancements
- Implement least-privilege IAM policies and roles.
- Add automated security checks to a GitHub Actions workflow.
- Add logging and monitoring controls.
- Expand the infrastructure with additional security-focused resources.

## Cleanup

When the lab is no longer needed, review the resources managed by Terraform and use the following command from the `terraform` directory if you intentionally want to remove them:

```powershell
terraform destroy
```

Review the proposed deletions before confirming. This removes Terraform-managed resources and may permanently delete data stored in them.

## Skills Demonstrated
AWS | Amazon S3 | Terraform | Infrastructure as Code | AWS CLI | Cloud Security | Encryption | Access Control | Git | GitHub
