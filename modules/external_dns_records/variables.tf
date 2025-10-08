variable "zone_name" {
  description = "Hosted zone name, e.g. example.com (required when creating a zone)."
  type        = string
  default     = null
}

variable "existing_zone_id" {
  description = "If set, use an existing hosted zone instead of creating a new one."
  type        = string
  default     = null
}

variable "private_zone" {
  description = "If true → create/expect a Private Hosted Zone (requires at least one VPC association)."
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "If true, destroy the hosted zone even if it contains records (deletes records first)."
  type        = bool
  default     = false
}

variable "allow_overwrite" {
  description = "Allow overwriting existing records with the same name/type."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID used when creating a new private hosted zone (optional if vpc_associations is used)."
  type        = string
  default     = null
}

variable "vpc_region" {
  description = "Region of vpc_id (optional; defaults to provider region if omitted)."
  type        = string
  default     = null
}

variable "vpc_associations" {
  description = "Additional/all VPC associations for a private hosted zone."
  type = list(object({
    vpc_id     = string
    vpc_region = optional(string)
  }))
  default = []
}

variable "a_records_list" {
  description = "A/AAAA records. Use alias for ALB/NLB/etc. name='@' or '' targets the zone apex."
  type = list(object({
    name    = string
    type    = optional(string, "A")
    ttl     = optional(number)
    records = optional(list(string))
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, false)
    }))
  }))
  default = []
}

variable "cname_records_list" {
  description = "CNAME records (not valid at the apex)."
  type = list(object({
    name   = string
    ttl    = number
    record = string
  }))
  default = []
}
