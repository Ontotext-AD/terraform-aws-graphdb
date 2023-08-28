# REQUIRED parameters

variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources"
  type        = string
}

# OPTIONAL parameters

variable "kms_key_arn" {
  description = "KMS key to use for bucket encryption."
  type        = string
  default     = null
}

variable "access_log_bucket" {
  description = "S3 bucket ID for storing access logs of the GraphDB backup bucket"
  type        = string
  default     = null
}
