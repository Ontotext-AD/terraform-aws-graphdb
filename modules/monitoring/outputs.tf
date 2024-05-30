output "cmk_arn" {
  description = "ARN of the KMS CMK"
  value       = var.enable_cmk && length(aws_kms_key.cmk) > 0 ? aws_kms_key.cmk[0].arn : null
}

output "cmk_alias_arn" {
  description = "ARN of the CMK Alias"
  value       = var.enable_cmk && length(aws_kms_alias.cmk_alias) > 0 ? aws_kms_alias.cmk_alias[0].arn : null
}