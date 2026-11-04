data "aws_caller_identity" "current" {}

# Backups are always SSE-KMS, and S3 replicates SSE-KMS objects only with a replica key in the destination region.
# DescribeKey on alias/aws/s3 also creates the AWS managed key if the region has never used it.
data "aws_kms_key" "replica" {
  provider = aws.bucket_replication_destination_region
  key_id   = "alias/aws/s3"
}

# Backup Replication S3 Bucket

resource "aws_s3_bucket" "graphdb_backup_replication_bucket" {
  provider = aws.bucket_replication_destination_region
  bucket   = "${var.resource_name_prefix}-backups-replication-bucket-${data.aws_caller_identity.current.account_id}"
}

# Explicitly disable public access
resource "aws_s3_bucket_public_access_block" "graphdb_backup_replication_bucket_public_access_block" {
  bucket = aws_s3_bucket.graphdb_backup_replication_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Backup Replication S3 Bucket ACL Configuration

resource "aws_s3_bucket_acl" "graphdb_backup_replication_acl" {
  bucket = aws_s3_bucket.graphdb_backup_replication_bucket.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.graphdb_backup_replication_ownership_controls]
}

# Backup Replication S3 Bucket Versioning Configuration

resource "aws_s3_bucket_versioning" "graphdb_backup_replication_versioning" {
  bucket = aws_s3_bucket.graphdb_backup_replication_bucket.id

  versioning_configuration {
    status     = var.versioning_enabled
    mfa_delete = var.mfa_delete
  }
}

# Backup Replication S3 Bucket Encryption Configuration

resource "aws_s3_bucket_server_side_encryption_configuration" "graphdb_backup_replication_sse_config" {
  bucket = aws_s3_bucket.graphdb_backup_replication_bucket.id

  rule {
    bucket_key_enabled       = true
    blocked_encryption_types = ["SSE-C"]

    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Ownership controls for the bucket

resource "aws_s3_bucket_ownership_controls" "graphdb_backup_replication_ownership_controls" {
  bucket = aws_s3_bucket.graphdb_backup_replication_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# S3 Bucket Replication Configuration

# Replicating from the backup bucket to the replication bucket

resource "aws_s3_bucket_replication_configuration" "graphdb_backup_bucket_replication" {
  # Must have bucket versioning enabled first

  depends_on = [aws_s3_bucket_versioning.graphdb_backup_replication_versioning]

  role   = var.s3_iam_role_arn
  bucket = var.graphdb_backup_bucket_id

  rule {
    status = var.enable_replication

    # V2 rule (filter): provider 6.27 sends an empty request body for a V1 rule with source_selection_criteria.
    filter {}

    delete_marker_replication {
      status = "Disabled"
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket = aws_s3_bucket.graphdb_backup_replication_bucket.arn

      encryption_configuration {
        replica_kms_key_id = data.aws_kms_key.replica.arn
      }
    }
  }
}

# Replicating from the replication bucket to the backup bucket

resource "aws_s3_bucket_replication_configuration" "graphdb_backup_replication_bucket_replication" {
  # Must have bucket versioning enabled first

  depends_on = [aws_s3_bucket_versioning.graphdb_backup_replication_versioning]

  provider = aws.bucket_replication_destination_region

  bucket = aws_s3_bucket.graphdb_backup_replication_bucket.id
  role   = var.s3_iam_role_arn

  rule {
    status = var.enable_replication

    destination {
      bucket = var.graphdb_backup_bucket_arn
    }
  }
}
