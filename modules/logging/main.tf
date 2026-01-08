data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "elb_account_id" {}
data "aws_region" "current" {}

# Logging S3 Bucket

resource "aws_s3_bucket" "graphdb_logging_bucket" {
  bucket = "${var.resource_name_prefix}-logging-${data.aws_caller_identity.current.account_id}"
}

# Explicitly disable public access
resource "aws_s3_bucket_public_access_block" "graphdb_logging_bucket_public_access_block" {
  bucket = aws_s3_bucket.graphdb_logging_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Logging S3 Bucket ACL Configuration

resource "aws_s3_bucket_acl" "graphdb_logging_acl" {
  bucket = aws_s3_bucket.graphdb_logging_bucket.id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_ownership_controls.graphdb_logging_ownership_controls]
}

# Logging S3 Bucket Versioning Configuration

resource "aws_s3_bucket_versioning" "graphdb_logging_versioning" {
  bucket = aws_s3_bucket.graphdb_logging_bucket.id

  versioning_configuration {
    status     = var.versioning_enabled
    mfa_delete = var.mfa_delete
  }
}

# Logging S3 Bucket Encryption Configuration

resource "aws_s3_bucket_server_side_encryption_configuration" "graphdb_logging_sse_config" {
  bucket = aws_s3_bucket.graphdb_logging_bucket.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Ownership controls for the bucket

resource "aws_s3_bucket_ownership_controls" "graphdb_logging_ownership_controls" {
  bucket = aws_s3_bucket.graphdb_logging_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Policy to allow Log Delivery to write logs into S3 bucket https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-access-logs.html

resource "aws_s3_bucket_policy" "graphdb_elb_s3_bucket_policy" {
  bucket = aws_s3_bucket.graphdb_logging_bucket.id
  policy = data.aws_iam_policy_document.graphdb_allow_log_delivery.json
}

data "aws_iam_policy_document" "graphdb_allow_log_delivery" {
  statement {
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.graphdb_logging_bucket.bucket}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
    ]
    actions = ["s3:PutObject"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_elb_service_account.elb_account_id.id}:root"]
    }
  }

  statement {
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.graphdb_logging_bucket.bucket}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
    ]
    actions = ["s3:PutObject"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.graphdb_logging_bucket.bucket}",
    ]
    actions = ["s3:GetBucketAcl"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}

# Lifecycle Configuration

resource "aws_s3_bucket_lifecycle_configuration" "logs_lifecycle_configuration" {
  bucket = aws_s3_bucket.graphdb_logging_bucket.id

  # Lifecycle rule for the S3 Access Logs

  rule {
    id     = "${var.resource_name_prefix}-s3-access-logs"
    status = var.s3_access_logs_lifecycle_rule_status

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_multipart_upload
    }

    filter {
      prefix = "s3_access_logs/"
    }

    expiration {
      days                         = var.s3_access_logs_expiration_days
      expired_object_delete_marker = true
    }
  }

  # Lifecycle rule for the LB access logs

  rule {
    id     = "${var.resource_name_prefix}-lb-access-logs"
    status = var.lb_access_logs_lifecycle_rule_status

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_multipart_upload
    }

    filter {
      prefix = "AWSLogs/"
    }

    expiration {
      days = var.lb_access_logs_expiration_days
    }
  }
  # Lifecycle rule for the VPC flow logs

  rule {
    id     = "${var.resource_name_prefix}-vpc-flow-logs"
    status = var.vpc_flow_logs_lifecycle_rule_status

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_multipart_upload
    }

    filter {
      prefix = "AWSLogs/${data.aws_caller_identity.current.account_id}/${data.aws_region.current.id}/vpcflowlogs/"
    }

    expiration {
      days = var.vpc_flow_logs_expiration_days
    }
  }
}
