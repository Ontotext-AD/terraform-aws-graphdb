output "graphdb_backup_replication_bucket_name" {
  description = "Output the bucket name"
  value       = aws_s3_bucket.graphdb_backup_replication_bucket.bucket
}
