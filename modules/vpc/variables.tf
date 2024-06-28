variable "resource_name_prefix" {
  description = "Prefix for resource names (e.g. \"prod\")"
  type        = string
}

variable "vpc_private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "vpc_public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

variable "vpc_dns_hostnames" {
  description = "Enable or disable DNS hostnames support for the VPC"
  type        = bool
}

variable "vpc_dns_support" {
  description = "Enable or disable the support of the DNS service"
  type        = bool
}

variable "single_nat_gateway" {
  description = "Enable or disable the option to have single NAT Gateway."
  type        = bool
}

variable "enable_nat_gateway" {
  description = "Enalbe or disable the creation of the NAT Gateway"
  type        = bool
}

variable "vpc_endpoint_service_accept_connection_requests" {
  description = "(Required) Whether or not VPC endpoint connection requests to the service must be accepted by the service owner - true or false."
  type        = bool
}

variable "vpc_endpoint_service_allowed_principals" {
  description = "(Optional) The ARNs of one or more principals allowed to discover the endpoint service."
  type        = list(string)
}

variable "network_load_balancer_arns" {
  description = "Describe the ARN(s) of the load balancer(s) to which you want to have access."
  type        = list(string)
}

variable "lb_enable_private_access" {
  description = "Enable or disable the private access via PrivateLink to the GraphDB Cluster"
  type        = bool
}

variable "vpc_enable_flow_logs" {
  description = "Enable or disable VPC Flow logs"
  type        = bool
}

variable "vpc_flow_log_bucket_arn" {
  description = "Define the ARN of the bucket for the VPC flow logs"
  type        = string
  default     = null
}

variable "graphdb_node_count" {
  description = "Number of GraphDB nodes to deploy in ASG"
  type        = number
}
