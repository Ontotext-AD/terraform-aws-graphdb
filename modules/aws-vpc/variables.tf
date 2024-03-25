variable "create_vpc" {
  description = "Enable or disable the creation of the VPC"
  type        = bool
}

variable "azs" {
  description = "availability zones to use in AWS region"
  type        = list(string)
}

variable "resource_name_prefix" {
  description = "Prefix for resource names (e.g. \"prod\")"
  type        = string
}

variable "vpc_private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = []
}

variable "vpc_public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = []
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
