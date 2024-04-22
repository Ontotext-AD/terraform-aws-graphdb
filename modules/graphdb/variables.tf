# Common parameters

variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.resource_name_prefix)) && !can(regex("^-", var.resource_name_prefix))
    error_message = "Resource name prefix cannot start with a hyphen and can only contain letters, numbers, and hyphens."
  }
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "aws_region" {
  description = "AWS region where GraphDB is being deployed"
  type        = string
}

variable "aws_subscription_id" {
  description = "AWS subscription ID of the account GraphDB is being deployed in"
  type        = string
}

# GraphDB Parameters

variable "graphdb_admin_password" {
  description = "Password for the 'admin' user in GraphDB."
  type        = string
  sensitive   = true
}

variable "graphdb_cluster_token" {
  description = "Cluster token used for authenticating the communication between the nodes."
  type        = string
  sensitive   = true
}

variable "graphdb_license_path" {
  description = "Local path to a file, containing a GraphDB Enterprise license."
  type        = string
  default     = null
}

variable "graphdb_properties_path" {
  description = "Path to a local file with with properties which will be appended to graphdb.properties"
  type        = string
}

variable "graphdb_java_options" {
  description = "Additional configurations to add to the GDB_JAVA_OPTS environment variable"
  type        = string
}

variable "graphdb_version" {
  description = "GraphDB version"
  type        = string
}

# IAM Parameters

variable "iam_instance_profile" {
  description = "IAM instance profile name to use for GraphDB instances"
  type        = string
}

variable "iam_role_id" {
  description = "IAM role ID to attach permission policies to"
  type        = string
}

# Network Parameters

variable "vpc_id" {
  description = "VPC ID where GraphDB will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-zA-Z0-9-]+$", var.vpc_id))
    error_message = "VPC ID must start with 'vpc-' and can only contain letters, numbers, and hyphens."
  }
}

variable "graphdb_subnets" {
  description = "Private subnets where GraphDB will be deployed"
  type        = list(string)
}

# Load Balancer Parameters

variable "graphdb_target_group_arns" {
  description = "Target group ARN(s) to register GraphDB nodes with"
  type        = list(string)
}

variable "graphdb_lb_dns_name" {
  description = "The DNS name of the load balancer for the GraphDB nodes."
  type        = string
}

variable "lb_subnets" {
  description = "The subnets used by the load balancer. If internet-facing use the public subnets, private otherwise."
  type        = list(string)
}

# Monitoring Parameters

variable "deploy_monitoring" {
  description = "Enable or disable toggle for monitoring"
  type        = bool
}

variable "enable_detailed_monitoring"{
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  type        = bool
}

# Backup Parameters

variable "deploy_backup" {
  description = "Deploy backup module"
  type        = bool
}

variable "backup_schedule" {
  description = "Cron expression for the backup job."
  type        = string
}

variable "backup_bucket_name" {
  description = "Name of the S3 bucket for storing GraphDB backups"
  type        = string

  validation {
    condition     = var.backup_bucket_name == "" || can(regex("^[a-z0-9_-]+$", var.backup_bucket_name))
    error_message = "Bucket name can only contain lowercase letters, numbers, hyphens, and underscores."
  }
}

# EBS Volume Parameters

variable "device_name" {
  description = "The device to which EBS volumes for the GraphDB data directory will be mapped."
  type        = string
}

variable "ebs_volume_type" {
  description = "Type of the EBS volumes, used by the GraphDB nodes."
  type        = string
}

variable "ebs_volume_size" {
  description = "The size of the EBS volumes, used by the GraphDB nodes."
  type        = number
}

variable "ebs_volume_throughput" {
  description = "Throughput for the EBS volumes, used by the GraphDB nodes."
  type        = number
}

variable "ebs_volume_iops" {
  description = "IOPS for the EBS volumes, used by the GraphDB nodes."
  type        = number
}

variable "ebs_kms_key_arn" {
  description = "KMS key used for ebs volume encryption."
  type        = string
}

# DNS Parameters

variable "route53_zone_dns_name" {
  description = "DNS name for the private hosted zone in Route 53"
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 private hosted zone id"
  type        = string
}

# Optional Parameters

variable "backup_retention_count" {
  description = "Number of backups to keep."
  type        = number
  default     = 7
}

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

variable "ec2_key_name" {
  description = "key pair to use for SSH access to instance"
  type        = string
  default     = null
}

variable "graphdb_node_count" {
  description = "Number of GraphDB nodes to deploy in ASG"
  type        = number
  default     = 3
}

variable "ec2_userdata_script" {
  description = "Userdata script for EC2 instance"
  type        = string
}

variable "lb_enable_private_access" {
  description = "Enable or disable the private access via PrivateLink to the GraphDB Cluster"
  type        = bool
}
