# REQUIRED parameters

variable "vpc_id" {
  description = "VPC ID where GraphDB will be deployed"
  type        = string
}

variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile name to use for GraphDB instances"
  type        = string
}

variable "iam_role_id" {
  description = "IAM role ID to attach permission policies to"
  type        = string
}

variable "userdata_script" {
  description = "Userdata script for EC2 instance"
  type        = string
}

variable "graphdb_subnets" {
  description = "Private subnets where GraphDB will be deployed"
  type        = list(string)
}

variable "graphdb_target_group_arns" {
  description = "Target group ARN(s) to register GraphDB nodes with"
  type        = list(string)
}

variable "lb_subnets" {
  description = "The subnets used by the load balancer. If internet-facing use the public subnets, private otherwise."
  type        = list(string)
}

variable "graphdb_version" {
  description = "GraphDB version"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

# OPTIONAL parameters

variable "ami_id" {
  description = "AMI ID to use with GraphDB instances"
  type        = string
  default     = null
}

variable "allowed_inbound_cidrs" {
  description = "List of CIDR blocks to permit inbound traffic from to load balancer"
  type        = list(string)
  default     = null
}

variable "allowed_inbound_cidrs_ssh" {
  description = "List of CIDR blocks to give SSH access to GraphDB nodes"
  type        = list(string)
  default     = null
}

variable "key_name" {
  description = "key pair to use for SSH access to instance"
  type        = string
  default     = null
}

variable "node_count" {
  description = "Number of GraphDB nodes to deploy in ASG"
  type        = number
  default     = 3
}
