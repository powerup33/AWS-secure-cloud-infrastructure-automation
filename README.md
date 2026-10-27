# ☁️ AWS Secure Cloud Infrastructure Automation

## 🎯 Project Overview

This project demonstrates how to provision and secure AWS infrastructure using Terraform and implement least-privilege access controls with AWS Identity and Access Management (IAM).

The project focuses on foundational cloud security practices, including secure Amazon S3 configuration, encryption at rest, versioning, and permission testing through hands-on labs.

## 🛠️ Technologies Used

- **Amazon Web Services (AWS):** Cloud infrastructure
- **Amazon S3:** Secure object storage
- **AWS IAM:** Identity and access management
- **Terraform:** Infrastructure as Code (IaC)
- **AWS IAM Policy Simulator:** Permission testing and troubleshooting
- **AWS CLI:** Cloud resource verification
- **Git and GitHub:** Version control and documentation

## Architecture

- **Cloud Provider:** Amazon Web Services
- **Region:** US East (Ohio) — `us-east-2`
- **Infrastructure:** Terraform-managed Amazon S3 bucket
- **Access Control:** IAM read-only policy
- **Security Focus:** Data protection, least privilege, encryption, and recoverability

## 🔒 Security Controls Implemented

### 1. S3 Public Access Protection

Configured all four Amazon S3 Block Public Access settings to help prevent unintended public exposure of stored data.

### 2. Encryption at Rest

Configured default server-side encryption using Amazon S3-managed keys (SSE-S3) with AES-256 encryption.

### 3. Bucket Versioning

Enabled S3 versioning to preserve previous object versions and support recovery from certain accidental changes or deletions.

### 4. Infrastructure as Code

Defined AWS resources using Terraform to make infrastructure deployment repeatable, consistent, and easier to manage.

### 5. IAM Least-Privilege Access

Created an IAM policy named `PortfolioS3ReadOnly` for the test user `portfolio-s3-readonly-test`.

The policy is designed to allow read access to the designated S3 bucket while withholding unnecessary write and deletion permissions.

**IAM Policy Simulator Results**

| S3 Action | Expected Result | Observed Result |
|---|---|---|
| `s3:ListBucket` | Allow | Allowed |
| `s3:GetObject` | Allow | Allowed |
| `s3:PutObject` | Deny | Denied |
| `s3:DeleteBucket` | Deny | Denied |

The simulator identified an AWS Organizations Service Control Policy (SCP) restriction during testing. The IAM policy was evaluated separately from that restriction to isolate its permissions.

These results demonstrate the evaluated IAM permissions. They do not, by themselves, verify successful or denied requests made by the test user against the live S3 bucket.

## 📁 Repository Structure

- `terraform/main.tf` — AWS provider configuration and S3 security resources
- `terraform/variables.tf` — Configurable project settings
- `terraform/outputs.tf` — Project information outputs
- `terraform/.terraform.lock.hcl` — Locked Terraform provider selections
- `.gitignore` — Excludes local and sensitive files from version control
- `README.md` — Project documentation

## Security Considerations

- Terraform state files and local Terraform working directories should remain excluded from version control.
- AWS credentials, access keys, and other sensitive information must never be committed to the repository.
- IAM permissions should follow the principle of least privilege.
- AWS Organizations SCPs can impose restrictions beyond the permissions granted by IAM policies.
- AWS budgets and alerts help monitor spending but do not automatically prevent charges.
- S3 storage, requests, and retained object versions may incur costs.

## 🚀 Future Enhancements

- Validate IAM permissions through controlled tests using the actual test identity, where permitted.
- Add automated infrastructure and security checks through GitHub Actions.
- Expand logging, monitoring, and security auditing capabilities.
- Document additional access-control scenarios and security validation results.
- Explore automated Terraform validation and deployment workflows.

## Skills Demonstrated

AWS | Amazon S3 | IAM | Least Privilege | Terraform | IaC | IAM Policy Simulation | AWS CLI | Cloud Security | Encryption | Access Control | Git | GitHub
