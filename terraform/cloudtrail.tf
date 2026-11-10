# ---------------------------------------------------------------------------
# CloudTrail: multi-region audit logging with log file validation,
# delivered to a dedicated, encrypted, TLS-only S3 bucket.
# ---------------------------------------------------------------------------

variable "trail_name" {
  description = "Name of the CloudTrail trail"
  type        = string
  default     = "secure-cloud-trail"
}

variable "log_retention_days" {
  description = "Days to keep CloudTrail logs before they expire"
  type        = number
  default     = 90
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  trail_arn  = "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${local.account_id}:trail/${var.trail_name}"
}

# --- Log bucket -------------------------------------------------------------

resource "aws_s3_bucket" "cloudtrail_logs" {
  #checkov:skip=CKV_AWS_145:Lab cost trade-off; SSE-S3 (AES-256) encryption is enforced instead of a paid KMS key
  #checkov:skip=CKV_AWS_18:Access logging would require a second bucket; out of scope for this lab
  #checkov:skip=CKV_AWS_144:Cross-region replication doubles storage cost; not needed for lab logs
  #checkov:skip=CKV2_AWS_62:No downstream consumer for S3 event notifications in this lab

  # Bucket names are global, so the account ID keeps this one unique
  bucket        = "${var.trail_name}-logs-${local.account_id}"
  force_destroy = true # lab setting: lets `terraform destroy` remove the bucket with logs in it
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket                  = aws_s3_bucket.cloudtrail_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"
    filter {}

    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# --- Bucket policy: let CloudTrail write, deny anything not over TLS --------

data "aws_iam_policy_document" "cloudtrail_logs" {
  statement {
    sid       = "AWSCloudTrailAclCheck"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_logs.arn]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid       = "AWSCloudTrailWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${local.account_id}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.cloudtrail_logs.arn,
      "${aws_s3_bucket.cloudtrail_logs.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_logs.json

  # The public access block must exist first, or the policy can be rejected
  depends_on = [aws_s3_bucket_public_access_block.cloudtrail_logs]
}

# --- The trail --------------------------------------------------------------

resource "aws_cloudtrail" "main" {
  #checkov:skip=CKV_AWS_35:Lab cost trade-off; logs are encrypted with SSE-S3 rather than a paid KMS CMK
  #checkov:skip=CKV_AWS_252:No alerting pipeline in this lab, so no SNS topic is needed
  #checkov:skip=CKV2_AWS_10:Logs are stored and reviewed in S3; CloudWatch Logs ingestion adds cost

  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  is_multi_region_trail         = true
  include_global_service_events = true # captures IAM, STS and other global API calls
  enable_log_file_validation    = true # lets you prove logs weren't tampered with

  # CloudTrail checks bucket permissions at creation, so the policy must exist first
  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]
}

# --- Outputs ----------------------------------------------------------------

output "cloudtrail_arn" {
  value = aws_cloudtrail.main.arn
}

output "cloudtrail_log_bucket" {
  value = aws_s3_bucket.cloudtrail_logs.id
}
