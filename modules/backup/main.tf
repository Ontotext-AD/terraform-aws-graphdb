data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_s3_bucket" "graphdb_backup" {
  bucket = "${var.resource_name_prefix}-backup-${data.aws_caller_identity.current.account_id}"
}

# Explicitly disable public access
resource "aws_s3_bucket_public_access_block" "backup" {
  bucket = aws_s3_bucket.graphdb_backup.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.graphdb_backup.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.s3_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.graphdb_backup.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "disallow-non-tls-access-to-bucket" {
  bucket = aws_s3_bucket.graphdb_backup.id
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
      aws_s3_bucket.graphdb_backup.arn,
      "${aws_s3_bucket.graphdb_backup.arn}/*",
    ]
    condition {
      variable = "aws:SecureTransport"
      test     = "Bool"
      values   = [false]
    }
  }
}

resource "aws_iam_role_policy" "s3_crud" {
  name   = "${var.resource_name_prefix}-graphdb-s3-crud"
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.backup_s3_crud.json
}

data "aws_iam_policy_document" "backup_s3_crud" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListObjects",
      "s3:PutObject",
      "s3:GetAccelerateConfiguration",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload",
      "s3:ListBucketVersions",
      "s3:DeleteObjectVersion"
    ]
    resources = [
      # the exact ARN is needed for the list bucket action, star for put,get,delete
      "arn:aws:s3:::${aws_s3_bucket.graphdb_backup.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.graphdb_backup.bucket}/*"
    ]
  }
}

resource "aws_s3_bucket_logging" "graphdb_backup_bucket_logs" {
  count = var.s3_enable_access_logs ? 1 : 0

  bucket = aws_s3_bucket.graphdb_backup.id

  target_bucket = var.s3_access_logs_bucket_name
  target_prefix = "s3_access_logs/"
}
