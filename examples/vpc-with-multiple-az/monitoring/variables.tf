variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region where GraphDB is being deployed"
  type        = string
}