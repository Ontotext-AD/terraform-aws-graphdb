# Common parameters
variable "deployment_restriction_tag" {
  description = "Deployment tag used to restrict access via IAM policies"
  type        = string
}

variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources."
  type        = string
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

variable "override_owner_id" {
  description = "Override the default owner ID used for the AMI images"
  type        = string
}

variable "assume_role_principal_arn" {
  description = "Define IAM Role principal for the policies"
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

# Network Parameters

variable "vpc_id" {
  description = "VPC ID where GraphDB will be deployed"
  type        = string
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

variable "enable_detailed_monitoring" {
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

variable "ebs_default_kms_key_arn" {
  description = "KMS key used for ebs volume encryption."
  type        = string
  default     = "alias/aws/ebs"
}

variable "create_ebs_kms_key" {
  description = "Enable or disable toggle for ebs volume encryption."
  type        = bool
}

variable "ebs_key_arn" {
  description = "ARN of the EBS KMS Key"
  type        = string
}

# DNS Parameters

variable "route53_zone_dns_name" {
  description = "DNS name for the private hosted zone in Route 53"
  type        = string
}

variable "route53_existing_zone_id" {
  description = "Define existing Route53 Zone ID"
  type        = string
}

# User Data Parameters

variable "external_address_protocol" {
  description = "External address HTTP string type"
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

variable "graphdb_enable_userdata_scripts_on_reboot" {
  description = "(Experimental) Modifies cloud-config to always run user data scripts on EC2 boot"
  type        = bool
}

variable "asg_enable_instance_refresh" {
  description = "Enables instance refresh for the GraphDB Auto scaling group"
  type        = bool
}

variable "asg_instance_refresh_min_healthy_percentage" {
  description = "Specifies the lower limit on the number of instances that must be in the InService state with a healthy status during an instance replacement activity."
  type        = number
  default     = 66
}

variable "asg_instance_refresh_instance_warmup" {
  description = "Number of seconds until a newly launched instance is configured and ready to use. Default behavior is to use the Auto Scaling Group's health check grace period."
  type        = number
  default     = 0
}

variable "asg_instance_refresh_skip_matching" {
  description = " Replace instances that already have your desired configuration."
  type        = bool
  default     = false
}

variable "asg_instance_refresh_checkpoint_delay" {
  description = "Number of seconds to wait after a checkpoint."
  type        = number
}

variable "lb_enable_private_access" {
  description = "Enable or disable the private access via PrivateLink to the GraphDB Cluster"
  type        = bool
}

variable "graphdb_logging_bucket_name" {
  description = "Define GraphDB logging bucket name"
  type        = string
}

variable "graphdb_logging_replication_bucket_name" {
  description = "Define GraphDB backup replication bucket name"
  type        = string
}

variable "graphdb_backup_bucket_name" {
  description = "Define GraphDB backup bucket name"
  type        = string
}

variable "graphdb_backup_replication_bucket_name" {
  description = "Define GraphDB backup replication bucket name"
  type        = string
}

variable "logging_enable_replication" {
  description = "Enable or disable logging bucket replication"
  type        = bool
}

variable "backup_enable_replication" {
  description = "Enable or disable backup bucket replication"
  type        = bool
}

# KMS encryption parameters

variable "parameter_store_key_admin_arn" {
  description = "ARN of the key administrator role for Parameter Store"
  type        = string
}

variable "parameter_store_key_tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
}

variable "parameter_store_key_rotation_enabled" {
  description = "Specifies whether key rotation is enabled."
  type        = bool
}

variable "parameter_store_cmk_alias" {
  description = "The alias for the CMK key."
  type        = string
}

variable "parameter_store_key_enabled" {
  description = "Specifies whether the key is enabled."
  type        = bool
}

variable "parameter_store_key_spec" {
  description = "Specification of the Key."
  type        = string
}

variable "parameter_store_key_deletion_window_in_days" {
  description = "The waiting period, specified in number of days for AWS to delete the KMS key(Between 7 and 30)."
  type        = number
}

variable "parameter_store_cmk_description" {
  description = "Description for the KMS Key"
  type        = string
}

variable "create_parameter_store_kms_key" {
  description = "Enable creation of KMS key for Parameter Store encryption"
  type        = bool
}

variable "parameter_store_external_kms_key" {
  description = "Externally provided KMS CMK"
  type        = string
}

variable "parameter_store_key_arn" {
  description = "Deifne the ARN for the KMS Key"
  type        = string
}

variable "parameter_store_default_key" {
  description = "Define default key for parameter store if no KMS key specified"
  type        = string
}

# EBS (KMS)

variable "ebs_key_admin_arn" {
  description = "ARN of the key administrator role for EBS"
  type        = string
}

variable "ebs_key_tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
}

variable "ebs_key_rotation_enabled" {
  description = "Specifies whether key rotation is enabled."
  type        = bool
}

variable "ebs_cmk_alias" {
  description = "The alias for the CMK key."
  type        = string
}

variable "ebs_key_enabled" {
  description = "Specifies whether the key is enabled."
  type        = bool
}

variable "ebs_key_spec" {
  description = "Specification of the Key."
  type        = string
}

variable "ebs_key_deletion_window_in_days" {
  description = "The waiting period, specified in number of days for AWS to delete the KMS key(Between 7 and 30)."
  type        = number
}

variable "ebs_cmk_description" {
  description = "Description for the KMS Key"
  type        = string
}

variable "ebs_external_kms_key" {
  description = "Externally provided KMS CMK"
  type        = string
}

variable "ebs_default_kms_key" {
  description = "Define default KMS key"
  type        = string
}

variable "instance_maintenance_policy_min_healthy_percentage" {
  description = "Define minimum healthy percentage for the Instance Maintenance Policy"
  type        = number
  default     = 66
}

variable "instance_maintenance_policy_max_healthy_percentage" {
  description = "Define maximum healthy percentage for the Instance Maintenance Policy"
  type        = number
  default     = 100
}
