# AWS Secure Cloud Infrastructure Automation

## Project Overview

This project demonstrates the use of Terraform to deploy and manage secure cloud infrastructure on Amazon Web Services (AWS).

The goal is to apply Infrastructure as Code (IaC) principles to implement foundational cloud security controls and document their configuration.

## Technologies Used

- **Amazon Web Services (AWS):** Cloud infrastructure
- **Amazon S3:** Secure object storage
- **Terraform:** Infrastructure as Code
- **AWS CLI:** Cloud resource verification
- **Git and GitHub:** Version control and project documentation

## Architecture

- **Cloud Provider:** Amazon Web Services
- **Region:** US East (Ohio) — `us-east-2`
- **Infrastructure:** Terraform-managed Amazon S3 bucket
- **Security Focus:** Data protection, access control, encryption, and recoverability

## Security Controls Implemented

### S3 Public Access Protection

Configured all four S3 Block Public Access settings to help prevent unintended public exposure of stored data.

### Encryption at Rest

Enabled default server-side encryption using Amazon S3-managed keys (SSE-S3) with AES-256 encryption.

### Bucket Versioning

Enabled S3 versioning to preserve previous object versions and support recovery from certain accidental changes or deletions.

### Infrastructure as Code

Defined AWS resources using Terraform to make infrastructure deployment repeatable, consistent, and easier to manage.

## Repository Structure

- `terraform/main.tf` — AWS provider configuration and S3 security resources
- `terraform/variables.tf` — Configurable project settings
- `terraform/outputs.tf` — Project information outputs
- `terraform/.terraform.lock.hcl` — Locked Terraform provider selections
- `.gitignore` — Excludes local and sensitive files from version control
- `README.md` — Project documentation

## Security Considerations

- Terraform state files and local Terraform working directories are excluded from version control.
- AWS credentials and other sensitive information should never be committed to the repository.
- AWS budgets and alerts help monitor spending but do not automatically prevent charges.
- S3 storage, requests, and retained object versions may incur costs.

## Future Enhancements

- Implement least-privilege AWS IAM policies and roles.
- Introduce automated security checks through GitHub Actions.
- Expand logging, monitoring, and security auditing capabilities.
- Add additional cloud security controls and document their effectiveness.

## Skills Demonstrated

AWS | Amazon S3 | Terraform | Infrastructure as Code | AWS CLI | Cloud Security | Encryption | Access Control | Git | GitHub