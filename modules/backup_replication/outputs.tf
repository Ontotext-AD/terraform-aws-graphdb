output "graphdb_backup_replication_bucket_name" {
  description = "Output the bucket name"
  value       = aws_s3_bucket.graphdb_backup_replication_bucket.bucket
}

output "replica_kms_key_arn" {
  description = "ARN of the KMS key that encrypts the backup replicas"
  value       = data.aws_kms_key.replica.arn
}
