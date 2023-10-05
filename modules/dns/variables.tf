variable "vpc_id" {
  description = "VPC ID where GraphDB will be deployed"
  type        = string
}

variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources"
  type        = string
}

variable "zone_dns_name" {
  description = "DNS name for the private hosted zone in Route 53"
  type        = string
}

variable "iam_role_id" {
  description = "IAM role ID to attach permission policies to"
  type        = string
}
