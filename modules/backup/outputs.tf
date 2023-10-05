output "bucket_name" {
  description = "Name of the S3 bucket for storing GraphDB backups"
  value       = aws_s3_bucket.backup.bucket
}

output "bucket_id" {
  description = "ID of the S3 bucket for storing GraphDB backups"
  value       = aws_s3_bucket.backup.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket for storing GraphDB backups"
  value       = aws_s3_bucket.backup.arn
}
