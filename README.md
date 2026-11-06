# 🔐 AWS Secure Cloud Infrastructure Automation

## 📌 Project Overview

This project demonstrates foundational AWS cloud security practices using Terraform, AWS IAM, Amazon S3, Python, and Boto3.

The goal is to deploy secure cloud infrastructure through Infrastructure as Code (IaC), implement least-privilege access controls, and automate basic IAM security auditing.

## 🛠️ Technologies Used

- **Amazon Web Services (AWS):** Cloud infrastructure
- **Amazon S3:** Secure object storage
- **AWS IAM:** Identity and access management
- **Terraform:** Infrastructure as Code
- **Python and Boto3:** AWS security auditing automation
- **AWS CLI:** Cloud resource verification
- **Git and GitHub:** Version control and project documentation

## 🏗️ Architecture

- **Cloud Provider:** Amazon Web Services
- **Region:** US East (Ohio) — `us-east-2`
- **Infrastructure:** Terraform-managed S3 bucket
- **Security Focus:** Data protection, least privilege, encryption, versioning, and IAM auditing

## 🔒 Security Controls Implemented

### 1. S3 Public Access Protection

Configured all four Amazon S3 Block Public Access settings to help prevent unintended public exposure of stored data.

### 2. Encryption at Rest

Enabled default server-side encryption using Amazon S3-managed keys (SSE-S3) with AES-256 encryption.

### 3. Bucket Versioning

Enabled S3 versioning to preserve previous object versions and support recovery from certain accidental changes or deletions.

### 4. IAM Least-Privilege Access

Created a test IAM user and attached a custom managed policy named `PortfolioS3ReadOnly`.

The policy grants:
- `s3:ListBucket` access to the designated portfolio bucket.
- `s3:GetObject` access to objects within that bucket.

Permissions are scoped to the specific bucket rather than granting broad S3 access.

### 5. Automated IAM Security Auditing

Developed Python scripts using Boto3 to inspect AWS IAM configuration.

**IAM User Inventory (`list_iam_users.py`)**
- Enumerates IAM users using pagination.
- Reports user creation dates.
- Identifies access keys and their status.
- Flags access keys older than 90 days.
- Retrieves access-key last-used information.
- Lists attached managed policies and their permission documents.
- Identifies inline IAM policies.

**IAM MFA Audit (`audit_iam_mfa.py`)**
- Retrieves the AWS account-level MFA summary.
- Enumerates IAM users using pagination.
- Checks whether MFA devices are assigned to IAM users.

## 📁 Repository Structure

```text
AWS-secure-cloud-infrastructure-automation/
│
├── .github/
├── scripts/
│   ├── list_iam_users.py
│   └── audit_iam_mfa.py
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── .terraform.lock.hcl
│
├── .gitignore
└── README.md
```

## 📊 Audit Findings

The IAM inventory script successfully identified the portfolio test user and reported:

- Zero access keys assigned.
- One attached managed policy: `PortfolioS3ReadOnly`.
- Bucket-scoped S3 list and object-read permissions.
- No inline policies found.

The MFA audit identified that no MFA device was assigned to the test IAM user.

**Audit limitation:** The account-level MFA summary checks root-user MFA status; it does not verify MFA protection for an AWS Builder ID sign-in. These are separate authentication mechanisms.

## ⚠️ Security Considerations

- Terraform state files and local Terraform working directories are excluded from version control.
- AWS credentials and sensitive variable files should never be committed to the repository.
- IAM audit scripts perform read-only inspection and do not modify AWS resources.
- AWS budgets and alerts help monitor spending but do not automatically prevent charges.
- S3 storage, requests, and retained object versions may incur costs.

## 🚀 Future Enhancements

- Add automated Terraform formatting and validation through GitHub Actions.
- Integrate infrastructure security scanning into CI/CD.
- Expand AWS logging, monitoring, and security auditing.
- Explore additional cloud security services after evaluating costs and account feature availability.

## 💻 Skills Demonstrated

AWS | Amazon S3 | IAM | Terraform | Infrastructure as Code | Python | Boto3 | AWS CLI | Least Privilege | Cloud Security | Encryption | Git | GitHub
