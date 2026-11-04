output "sns_cmk_arn" {
  description = "ARN of the KMS CMK"
  value       = local.create_sns_cmk ? aws_kms_key.sns_cmk[0].arn : ""
}

output "sns_cmk_alias_arn" {
  description = "ARN of the CMK Alias"
  value       = local.create_sns_cmk ? aws_kms_alias.sns_cmk_alias[0].arn : ""
}
