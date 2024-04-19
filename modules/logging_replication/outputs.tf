output "graphdb_logging_bucket_name" {
  description = "Output the bucket name"
  value       = aws_s3_bucket.graphdb_logging_replication_bucket.bucket
}
