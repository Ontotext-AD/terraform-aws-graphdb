# REQUIRED parameters

variable "vpc_id" {
  description = "Identifier of the VPC where GraphDB will be deployed."
  type        = string
}

variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources."
  type        = string
}

variable "lb_subnets" {
  description = "Collection of subnet identifiers where load balancer will be deployed."
  type        = list(string)
}

# OPTIONAL parameters

variable "lb_internal" {
  description = "(Optional) Whether the load balancer will be internal or internet-facing. Defaults to true."
  type        = bool
  default     = false
}

variable "lb_deregistration_delay" {
  description = "(Optional) Amount time, in seconds, for GraphDB LB target group to wait before changing the state of a deregistering target from draining to unused. Defaults to 300."
  type        = string
  default     = 300
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

variable "tls_enabled" {
  description = "If enabled, a certificate must be imported in ACM and its ARN to set in tls_certificate_arn. Certificates with RSA keys larger than 2048-bit or EC keys cannot be used."
  type        = bool
  default     = false
}

variable "tls_policy" {
  description = "TLS security policy on the listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "tls_certificate_arn" {
  description = "ARN of the certificate, imported in ACM, which will be used for the TLS listener on the load balancer."
  type        = string
  default     = null
}