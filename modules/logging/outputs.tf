output "graphdb_logging_bucket_name" {
  description = "Output the bucket name"
  value       = aws_s3_bucket.graphdb_logging_bucket.bucket
}

output "graphdb_logging_bucket_arn" {
  description = "Output the bucket ARN"
  value       = aws_s3_bucket.graphdb_logging_bucket.arn
}

output "graphdb_logging_bucket_id" {
  value = aws_s3_bucket.graphdb_logging_bucket.id
}
