variable "vpc_id" {
  description = "VPC ID where GraphDB will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-zA-Z0-9-]+$", var.vpc_id))
    error_message = "VPC ID must start with 'vpc-' and can only contain letters, numbers, and hyphens."
  }
}

variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.resource_name_prefix)) && !can(regex("^-", var.resource_name_prefix))
    error_message = "Resource name prefix cannot start with a hyphen and can only contain letters, numbers, and hyphens."
  }

}

variable "lb_subnets" {
  description = "Collection of subnet identifiers where load balancer will be deployed."
  type        = list(string)
}

variable "lb_security_groups" {
  description = "(Optional) Security groups to assign when the LB is internal."
  type        = list(string)
  default     = []
}

variable "lb_internal" {
  description = "(Optional) Whether the load balancer will be internal or internet-facing. Defaults to true."
  type        = bool
  default     = false
}

variable "lb_deregistration_delay" {
  description = "(Optional) Amount time, in seconds, for GraphDB LB target group to wait before changing the state of a deregistering target from draining to unused. Defaults to 300."
  type        = number
  default     = 300
}

variable "lb_healthy_threshold" {
  description = "(Optional) Number of consecutive health check successes required to consider GraphDB target healthy"
  type        = number
  default     = 3
}

variable "lb_unhealthy_threshold" {
  description = "(Optional) Number of consecutive health check failures   required before considering a GraphDB target unhealthy"
  type        = number
  default     = 3
}

variable "lb_health_check_path" {
  description = "(Optional) The endpoint to check for GraphDB's health status. Defaults to /protocol."
  type        = string
  default     = "/rest/cluster/node/status"
}

variable "lb_health_check_interval" {
  description = "(Optional) Interval in seconds for checking the target group healthcheck. Defaults to 10."
  type        = number
  default     = 10
}

variable "lb_enable_deletion_protection" {
  description = "(Optional) Defines if the load balancer should be protected from deletion or not. Defaults to true."
  type        = bool
  default     = true
}

# TLS

variable "lb_tls_certificate_arn" {
  description = "ARN of the TLS certificate, imported in ACM, which will be used for the TLS listener on the load balancer."
  type        = string
  default     = null
}

variable "lb_tls_policy" {
  description = "TLS security policy on the listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}
