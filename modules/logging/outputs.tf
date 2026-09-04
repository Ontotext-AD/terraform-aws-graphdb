output "graphdb_logging_bucket_name" {
  description = "Output the bucket name"
  value       = aws_s3_bucket.graphdb_logging_bucket.bucket
  # Consumers (LB access logs, backup S3 access logs) write to this bucket
  # via APIs that validate the destination's bucket policy synchronously,
  # so they must not resolve this output until the policy is in place.
  depends_on = [aws_s3_bucket_policy.graphdb_elb_s3_bucket_policy]
}

output "graphdb_logging_bucket_arn" {
  description = "Output the bucket ARN"
  value       = aws_s3_bucket.graphdb_logging_bucket.arn
  # VPC flow logs (S3 destination) validate the destination's bucket policy
  # synchronously at creation time, so this output must wait for it too.
  depends_on = [aws_s3_bucket_policy.graphdb_elb_s3_bucket_policy]
}

output "graphdb_logging_bucket_id" {
  value = aws_s3_bucket.graphdb_logging_bucket.id
}
