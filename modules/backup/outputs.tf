output "bucket_name" {
  description = "Name of the S3 bucket for storing GraphDB backups"
  value       = aws_s3_bucket.graphdb_backup.bucket
}

output "bucket_id" {
  description = "ID of the S3 bucket for storing GraphDB backups"
  value       = aws_s3_bucket.graphdb_backup.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket for storing GraphDB backups"
  value       = aws_s3_bucket.graphdb_backup.arn
}

output "s3_cmk_arn" {
  description = "ARN of the KMS key for S3 bucket encryption"
  value       = var.create_s3_kms_key ? aws_kms_key.s3_cmk[0].arn : ""
}

output "s3_cmk_alias_arn" {
  description = "ARN of the KMS key alias for S3 bucket encryption"
  value       = var.create_s3_kms_key ? aws_kms_alias.s3_cmk_alias[0].arn : ""
}

output "key_admin_iam_role_arn" {
  description = "IAM Role to use for replication"
  value       = aws_iam_role.graphdb_s3_key_admin_role.arn
}

output "key_admin_iam_role_name" {
  description = "Outputs the IAM Role name for the S3 Key Admin Role"
  value       = aws_iam_role.graphdb_s3_key_admin_role.name
}
