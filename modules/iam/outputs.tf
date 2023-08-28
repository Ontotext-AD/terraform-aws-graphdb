output "aws_iam_instance_profile" {
  value = aws_iam_instance_profile.graphdb.name
}

output "backups_bucket_key_id" {
  value = aws_iam_access_key.this.id
}

output "backups_bucket_key_secret" {
  value     = aws_iam_access_key.this.secret
  sensitive = true
}
