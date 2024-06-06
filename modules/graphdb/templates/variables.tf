
variable "graphdb_ebs_key_admin_arn" {
  description = "ARN of the key administrator role for Parameter Store"
  type        = string
}


variable "graphdb_ebs_key_tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
}

variable "graphdb_ebs_key_rotation_enabled" {
  description = "Specifies whether key rotation is enabled."
  type        = bool
}

variable "graphdb_ebs_cmk_alias" {
  description = "The alias for the CMK key."
  type        = string
}

variable "graphdb_ebs_key_enabled" {
  description = "Specifies whether the key is enabled."
  type        = bool
}

variable "graphdb_ebs_key_spec" {
  description = "Specification of the Key."
  type        = string
}

variable "graphdb_ebs_key_deletion_window_in_days" {
  description = "The waiting period, specified in number of days for AWS to delete the KMS key(Between 7 and 30)."
  type        = number
}

variable "graphdb_ebs_cmk_description" {
  description = "Description for the KMS Key"
  type        = string
}

variable "enable_graphdb_ebs_kms_key" {
  description = "Enable creation of KMS key for Parameter Store encryption"
  type        = bool
}

variable "ebs_external_kms_key" {
  description = "Externally provided KMS CMK"
  type        = string
  default     = "arn:aws:kms:us-east-1:590184002875:key/88617de9-2585-4124-98c1-49eef06b3ef6"
}
