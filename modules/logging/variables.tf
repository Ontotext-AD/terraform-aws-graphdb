variable "kms_key_arn" {
  description = "KMS key to use for bucket encryption. If left empty, it will use the account's default for S3."
  type        = string
  default     = null
}

variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources"
  type        = string
}

variable "s3_access_logs_lifecycle_rule_status" {
  description = "Define status of the S3 lifecycle rule. Possible options are enabled or disabled."
  type        = string
}

variable "lb_access_logs_lifecycle_rule_status" {
  description = "Define status of the S3 lifecycle rule. Possible options are enabled or disabled."
  type        = string
}

variable "s3_access_logs_expiration_days" {
  description = "Define the days after which the S3 access logs should be deleted."
  type        = number
}

variable "lb_access_logs_expiration_days" {
  description = "Define the days after which the LB access logs should be deleted."
  type        = number
}

variable "expired_object_delete_marker" {
  description = "Indicates whether Amazon S3 will remove a delete marker with no noncurrent versions. If set to true, the delete marker will be expired; if set to false the policy takes no action."
  type        = bool
}

variable "mfa_delete" {
  description = "Enable MFA delete for either Change the versioning state of your bucket or Permanently delete an object version. Default is false. This cannot be used to toggle this setting but is available to allow managed buckets to reflect the state in AWS"
  type        = string
}

variable "versioning_enabled" {
  description = "Enable versioning. Once you version-enable a bucket, it can never return to an unversioned state. You can, however, suspend versioning on that bucket."
  type        = string
}

variable "abort_multipart_upload" {
  description = "Specifies the number of days after initiating a multipart upload when the multipart upload must be completed."
  type        = number
}

variable "vpc_flow_logs_lifecycle_rule_status" {
  description = "Define status of the S3 lifecycle rule. Possible options are enabled or disabled."
  type        = string
}

variable "vpc_flow_logs_expiration_days" {
  description = "Define the days after which the VPC flow logs should be deleted"
  type        = number
}
