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
  description = "Enable or disable the creation of the NAT Gateway"
  type        = bool
}

variable "nat_gateway_mode" {
  description = <<EOT
NAT Gateway deployment mode:
- single   : one zonal NAT in the first public subnet
- per_az   : one zonal NAT per public subnet/AZ
- regional : one regional NAT per VPC (AWS provider v6.24.0+)

If unset, the value is derived from single_nat_gateway for backward compatibility.
EOT
  type        = string
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

variable "tgw_id" {
  type        = string
  default     = null
  description = "Transit Gateway ID. If null, no TGW attachment will be created."
}

variable "tgw_subnet_ids" {
  type        = list(string)
  default     = []
  description = "List of subnet IDs to use for TGW attachment ENIs (typically private subnets)."
}

variable "tgw_client_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDRs of client networks reachable via TGW. Adds routes in private route tables."
}

variable "tgw_subnet_cidrs" {
  type        = list(string)
  description = "List of private route table IDs. Required if tgw_id is set."
  default     = []
}

variable "tgw_dns_support" {
  description = "Enable or disable DNS support in the TGW attachment"
  type        = string
}

variable "tgw_ipv6_support" {
  description = "Enable or disable IPv6 support in the TGW attachment"
  type        = string
}

variable "tgw_appliance_mode_support" {
  description = "Enable or disable Appliance Mode support in the TGW attachment"
  type        = string
}

variable "tgw_route_table_id" {
  description = "TGW route table to associate this VPC attachment with (client-provided). If null, no association is created."
  type        = string
}

variable "tgw_associate_to_route_table" {
  description = "Whether to associate the TGW attachment to tgw_route_table_id."
  type        = bool
}

variable "tgw_enable_propagation" {
  description = "Whether to enable propagation of this attachment into tgw_route_table_id."
  type        = bool
}
