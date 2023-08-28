# REQUIRED parameters

variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources"
  type        = string
}

# OPTIONAL parameters

variable "permissions_boundary" {
  description = "(Optional) IAM Managed Policy to serve as permissions boundary for IAM Role"
  type        = string
  default     = null
}

variable "user_supplied_iam_role_name" {
  description = "(OPTIONAL) User-provided IAM role name. This will be used for the instance profile provided to the AWS launch configuration. The minimum permissions must match the defaults generated by the IAM submodule for cloud auto-join and auto-unseal."
  type        = string
  default     = null
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket, where GraphDB backups are stored."
  type        = string
  default     = null
}
