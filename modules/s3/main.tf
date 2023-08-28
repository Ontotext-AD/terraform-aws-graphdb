resource "aws_s3_bucket" "backup" {
  bucket = "${var.resource_name_prefix}-graphdb-backup"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "backup" {
  count         = var.access_log_bucket != null ? 1 : 0
  bucket        = aws_s3_bucket.backup.id
  target_bucket = var.access_log_bucket
  target_prefix = "${var.resource_name_prefix}-graphdb-backup-access-logs/"
}

resource "aws_s3_bucket_policy" "disallow-non-tls-access-to-bucket" {
  bucket = aws_s3_bucket.backup.id
  policy = data.aws_iam_policy_document.disallow-non-tls-access-to-bucket.json
}

data "aws_iam_policy_document" "disallow-non-tls-access-to-bucket" {
  version = "2012-10-17"

  statement {
    sid     = "AllowSSLRequestsOnly"
    actions = ["s3:*"]
    effect  = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      aws_s3_bucket.backup.arn,
      "${aws_s3_bucket.backup.arn}/*",
    ]
    condition {
      variable = "aws:SecureTransport"
      test     = "Bool"
      values   = [false]
    }
  }
}
