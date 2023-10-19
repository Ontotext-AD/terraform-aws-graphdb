# REQUIRED parameters

variable "aws_region" {
  description = "AWS region where GraphDB is being deployed"
  type        = string

  validation {
    condition = contains(["us-east-2", "us-east-1", "us-west-1", "us-west-2", "af-south-1", "ap-east-1", "ap-south-2", "ap-southeast-3", "ap-southeast-4", "ap-south-1", "ap-northeast-3", "ap-northeast-2", "ap-southeast-1", "ap-southeast-2", "ap-northeast-1", "ca-central-1", "eu-central-1", "eu-west-1", "eu-west-2", "eu-south-1", "eu-west-3", "eu-south-2", "eu-north-1", "eu-central-2", "il-central-1", "me-south-1", "me-central-1", "sa-east-1"], var.aws_region)
    error_message = "The provided AWS region is not in the list of allowed regions."
  }
}

variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources"
  type        = string
}

variable "device_name" {
  description = "The device to which EBS volumes for the GraphDB data directory will be mapped."
  type        = string
}

variable "backup_schedule" {
  description = "Cron expression for the backup job."
  type        = string

  #TO BE DONE SOON - Doesn't work yet
  
  # validation {
  #   condition     = can(regex("^[0-9*?/,-]+$", var.backup_schedule))
  #   error_message = "Backup schedule must be a valid cron expression."
  # }
}

variable "backup_bucket_name" {
  description = "Name of the S3 bucket for storing GraphDB backups"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9_-]+$", var.backup_bucket_name))
    error_message = "Bucket name can only contain lowercase letters, numbers, hyphens, and underscores."
  }
}

variable "ebs_volume_type" {
  description = "Type of the EBS volumes, used by the GraphDB nodes."
  type        = string
}

variable "ebs_volume_size" {
  description = "The size of the EBS volumes, used by the GraphDB nodes."
  type        = number
}

variable "ebs_volume_throughput" {
  description = "Throughput for the EBS volumes, used by the GraphDB nodes."
  type        = number
}

variable "ebs_volume_iops" {
  description = "IOPS for the EBS volumes, used by the GraphDB nodes."
  type        = number
}

variable "ebs_kms_key_arn" {
  description = "KMS key used for ebs volume encryption."
  type        = string
}

variable "zone_dns_name" {
  description = "DNS name for the private hosted zone in Route 53"
  type        = string
}

variable "zone_id" {
  description = "Route 53 private hosted zone id"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

# OPTIONAL parameters

variable "user_supplied_userdata_path" {
  description = "File path to custom userdata script being supplied by the user"
  type        = string
  default     = null
}

variable "backup_retention_count" {
  description = "Number of backups to keep."
  type        = number
  default     = 7
}
