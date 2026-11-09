# Least-privilege, read-only access to the portfolio bucket.
# These resources were first created by hand in the console and then
# brought under Terraform management with `terraform import`.

data "aws_iam_policy_document" "portfolio_s3_read_only" {
  statement {
    sid       = "ListPortfolioBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.secure_storage.arn]
  }

  statement {
    sid       = "ReadPortfolioObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.secure_storage.arn}/*"]
  }
}

resource "aws_iam_policy" "portfolio_s3_read_only" {
  name        = "PortfolioS3ReadOnly"
  description = "Allows listing the portfolio S3 bucket and reading objects within that bucket only."
  policy      = data.aws_iam_policy_document.portfolio_s3_read_only.json
}

resource "aws_iam_user" "portfolio_s3_readonly_test" {
  #checkov:skip=CKV_AWS_273:Single test user for the audit demo. Production would use SSO instead of IAM users.
  name = "portfolio-s3-readonly-test"
}

resource "aws_iam_user_policy_attachment" "portfolio_s3_readonly_test" {
  #checkov:skip=CKV_AWS_40:Test user has one scoped read-only policy. Production would attach policies to groups or roles.
  user       = aws_iam_user.portfolio_s3_readonly_test.name
  policy_arn = aws_iam_policy.portfolio_s3_read_only.arn
}