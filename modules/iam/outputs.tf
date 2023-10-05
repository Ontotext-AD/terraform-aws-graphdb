output "iam_instance_profile" {
  description = "Instance profile to use for EC2"
  value       = aws_iam_instance_profile.graphdb.name
}

output "iam_role_id" {
  description = "IAM role ID to use for policies"
  value       = var.user_supplied_iam_role_name != null ? var.user_supplied_iam_role_name : aws_iam_role.graphdb[0].id
}
