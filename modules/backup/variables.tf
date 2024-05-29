variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources"
  type        = string
}

variable "iam_role_id" {
  description = "IAM role ID to attach permission policies to"
  type        = string
}

variable "s3_kms_key_arn" {
  description = "KMS key to use for bucket encryption. If left empty, it will use the account's default for S3."
  type        = string
}

variable "s3_enable_access_logs" {
  description = "Enable or disable access logs"
  type        = bool
}

variable "s3_access_logs_bucket_name" {
  description = "Define name for the S3 access logs"
  type        = string
}

# KMS CMK

variable "create_s3_kms_key" {
  description = "Enable creation of KMS key for S3 bucket encryption"
  type        = bool
}

variable "s3_key_rotation_enabled" {
  description = "Specifies whether key rotation is enabled."
  type        = bool
}

variable "s3_default_kms_key" {
  description = "Define default kms key if no KMS key specified"
  type        = string
}

variable "s3_cmk_alias" {
  description = "The alias for the CMK key."
  type        = string
}

variable "s3_kms_key_enabled" {
  description = "Specifies whether the key is enabled."
  type        = bool
}

variable "s3_key_specification" {
  description = "Specification of the Key."
  type        = string
}

variable "s3_key_deletion_window_in_days" {
  description = "The waiting period, specified in number of days for AWS to delete the KMS key(Between 7 and 30)."
  type        = number
}

variable "s3_kms_key_admin_arn" {
  description = "ARN of the role or user granted administrative access to the SNS KMS key."
  type        = string
}

variable "s3_cmk_description" {
  description = "Description for the KMS Key"
  type        = string
}

variable "s3_external_kms_key" {
  description = "Externally provided KMS CMK"
  type        = string
}

variable "iam_role_arn" {
  description = "Define IAM Role ARN to use in the KMS Key Policy"
  type        = string
}
