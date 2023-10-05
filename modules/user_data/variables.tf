# REQUIRED parameters

variable "aws_region" {
  description = "AWS region where GraphDB is being deployed"
  type        = string
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
}

variable "backup_bucket_name" {
  description = "Name of the S3 bucket for storing GraphDB backups"
  type        = string
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
