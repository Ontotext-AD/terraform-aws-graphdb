output "graphdb_ebs_cmk_arn" {
  value       = var.enable_graphdb_ebs_kms_key ? aws_kms_key.ebs_cmk[0].arn : ""
  description = "ARN of the KMS key for Parameter Store encryption"
}

output "graphdb_ebs_cmk_alias_arn" {
  value       = var.enable_graphdb_ebs_kms_key ? aws_kms_alias.graphdb_ebs_cmk_alias[0].arn : ""
  description = "ARN of the KMS key alias for Parameter Store encryption"
}
