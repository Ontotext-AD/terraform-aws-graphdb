variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.resource_name_prefix))
    error_message = "Resource name prefix can only contain letters, numbers, underscores, and hyphens."
  }
}

variable "iam_role_id" {
  description = "IAM role ID to attach permission policies to"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key to use for bucket encryption. If left empty, it will use the account's default for S3."
  type        = string
  default     = null
}
