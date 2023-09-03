variable "vpc_id" {
  description = "VPC ID where GraphDB will be deployed"
  type        = string
}

variable "zone_dns_name" {
  description = "DNS name for the private hosted zone in Route 53"
  type        = string
}
