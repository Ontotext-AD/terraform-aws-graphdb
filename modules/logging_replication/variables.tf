variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources"
  type        = string
}

variable "mfa_delete" {
  description = "Enable MFA delete for either Change the versioning state of your bucket or Permanently delete an object version. Default is false. This cannot be used to toggle this setting but is available to allow managed buckets to reflect the state in AWS"
  type        = string
}

variable "versioning_enabled" {
  description = "Enable versioning. Once you version-enable a bucket, it can never return to an unversioned state. You can, however, suspend versioning on that bucket."
  type        = string
}

variable "s3_iam_role_arn" {
  description = "IAM role ARN to attach permission policies to"
  type        = string
}

variable "enable_replication" {
  description = "Enable or disable S3 Bucket replication"
  type        = string
}

variable "graphdb_logging_bucket_id" {
  description = "Define GraphDB logging bucket name"
  type        = string
}

variable "graphdb_logging_bucket_arn" {
  description = "Define GraphDB logging bucket ARN"
  type        = string
}
