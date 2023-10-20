variable "vpc_id" {
  description = "VPC ID where GraphDB will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-zA-Z0-9-]+$", var.vpc_id))
    error_message = "VPC ID must start with 'vpc-' and can only contain letters, numbers, and hyphens."
  }
}

variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.resource_name_prefix))
    error_message = "Resource name prefix can only contain letters, numbers, and hyphens."
  }
}

variable "zone_dns_name" {
  description = "DNS name for the private hosted zone in Route 53"
  type        = string
}

variable "iam_role_id" {
  description = "IAM role ID to attach permission policies to"
  type        = string
}
