variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
}

variable "azs" {
  description = "Availability zones to use in AWS region"
  type        = list(string)
}

variable "resource_name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "graphdb_license_path" {
  description = "Local path to a file, containing a GraphDB Enterprise license."
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "ami_id" {
  description = "AMI id"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = null
}

variable "graphdb_version" {
  description = "GraphDB version"
  type        = string
  default     = null
}

variable "sns_topic_endpoint" {
  description = "Define an SNS endpoint which will be receiving the alerts via email"
  type = string
}

variable "log_group_retention_in_days" {
  description = "Log group retention in days"
  type = number
}
