output "graphdb_logging_bucket_name" {
  description = "Output the bucket name"
  value       = aws_s3_bucket.graphdb_logging_bucket.bucket

  depends_on = [
    aws_s3_bucket_policy.graphdb_elb_s3_bucket_policy,
    aws_s3_bucket_acl.graphdb_logging_acl,
  ]
}

output "graphdb_logging_bucket_arn" {
  description = "Output the bucket ARN"
  value       = aws_s3_bucket.graphdb_logging_bucket.arn

  depends_on = [
    aws_s3_bucket_policy.graphdb_elb_s3_bucket_policy,
    aws_s3_bucket_acl.graphdb_logging_acl,
  ]
}

output "graphdb_logging_bucket_id" {
  value = aws_s3_bucket.graphdb_logging_bucket.id
}
