terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "secure_storage" {
  #checkov:skip=CKV_AWS_144:Lab project. Cross-region replication would double storage cost. Production would replicate to a second region.
  #checkov:skip=CKV2_AWS_62:No downstream consumer of bucket events in this project.
  #checkov:skip=CKV_AWS_145:Bucket uses SSE-S3 (AES-256) encryption at rest. A customer-managed KMS key adds about $1/month and key management for a lab. Production would use SSE-KMS with a customer-managed key.
  #checkov:skip=CKV_AWS_18:S3 server access logging needs a dedicated log bucket. Production would enable server access logs or CloudTrail data events.
  bucket = "aws-secure-cloud-portfolio-mh-2026"

  tags = {
    Name        = "AWS-secure-cloud-infrastructure-automation"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Cloud-Security-Portfolio"
  }
}

resource "aws_s3_bucket_public_access_block" "secure_storage" {
  bucket = aws_s3_bucket.secure_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure_storage" {
  bucket = aws_s3_bucket.secure_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "secure_storage" {
  bucket = aws_s3_bucket.secure_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Controls the storage cost of versioning: expires old versions and
# cleans up failed multipart uploads. Current objects are left alone.
resource "aws_s3_bucket_lifecycle_configuration" "secure_storage" {
  bucket = aws_s3_bucket.secure_storage.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.secure_storage]
}

# Deny any request that does not use TLS (encrypted in transit)
data "aws_iam_policy_document" "secure_storage_tls" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      aws_s3_bucket.secure_storage.arn,
      "${aws_s3_bucket.secure_storage.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "secure_storage" {
  bucket     = aws_s3_bucket.secure_storage.id
  policy     = data.aws_iam_policy_document.secure_storage_tls.json
  depends_on = [aws_s3_bucket_public_access_block.secure_storage]
}