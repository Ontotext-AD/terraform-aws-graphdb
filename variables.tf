# Common configurations

variable "common_tags" {
  description = "(Optional) Map of common tags for all taggable AWS resources."
  type        = map(string)
  default     = {}
}

variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
}

variable "override_owner_id" {
  description = "Override the default owner ID used for the AMI images"
  type        = string
  default     = null
}

# Backup configurations
variable "deploy_backup" {
  description = "Deploy backup module"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Cron expression for the backup job."
  type        = string
  default     = "0 0 * * *"
}

variable "backup_retention_count" {
  description = "Number of backups to keep."
  type        = number
  default     = 7
}

variable "backup_enable_bucket_replication" {
  description = "Enable or disable S3 bucket replication"
  type        = bool
  default     = false
}

# Load balancer & TLS

variable "lb_internal" {
  description = "Whether the load balancer will be internal or public"
  type        = bool
  default     = false
}

variable "lb_deregistration_delay" {
  description = "Amount time, in seconds, for GraphDB LB target group to wait before changing the state of a deregistering target from draining to unused."
  type        = string
  default     = 300
}

variable "lb_health_check_path" {
  description = "The endpoint to check for GraphDB's health status."
  type        = string
  default     = "/rest/cluster/node/status"
}

variable "lb_health_check_interval" {
  description = "(Optional) Interval in seconds for checking the target group healthcheck. Defaults to 10."
  type        = number
  default     = 10
}

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

variable "allowed_inbound_cidrs_lb" {
  description = "(Optional) List of CIDR blocks to permit inbound traffic from to load balancer"
  type        = list(string)
  default     = null
}

variable "allowed_inbound_cidrs_ssh" {
  description = "(Optional) List of CIDR blocks to permit for SSH to GraphDB nodes"
  type        = list(string)
  default     = null
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "r6g.2xlarge"
  nullable    = false
}

variable "ec2_key_name" {
  description = "(Optional) key pair to use for SSH access to instance"
  type        = string
  default     = null
}

variable "graphdb_node_count" {
  description = "Number of GraphDB nodes to deploy in ASG"
  type        = number
  default     = 3
}

variable "vpc_dns_hostnames" {
  description = "Enable or disable DNS hostnames support for the VPC"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "Specify the VPC ID if you want to use existing VPC. If left empty it will create a new VPC"
  type        = string
  default     = ""
}

variable "vpc_public_subnet_ids" {
  description = "Define the Subnet IDs for the public subnets that are deployed within the specified VPC in the vpc_id variable"
  type        = list(string)
  default     = []
}

variable "vpc_private_subnet_ids" {
  description = "Define the Subnet IDs for the private subnets that are deployed within the specified VPC in the vpc_id variable"
  type        = list(string)
  default     = []
}

variable "vpc_private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default = [
    "10.0.0.0/19",
    "10.0.32.0/19",
    "10.0.64.0/19",
  ]
}

variable "vpc_public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default = [
    "10.0.128.0/20",
    "10.0.144.0/20",
    "10.0.160.0/20",
  ]
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_dns_support" {
  description = "Enable or disable the support of the DNS service"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Enable or disable the option to have single NAT Gateway."
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Enable or disable the creation of the NAT Gateway"
  type        = bool
  default     = true
}

variable "vpc_endpoint_service_accept_connection_requests" {
  description = "(Required) Whether or not VPC endpoint connection requests to the service must be accepted by the service owner - true or false."
  type        = bool
  default     = true
}

variable "vpc_endpoint_service_allowed_principals" {
  description = "(Optional) The ARNs of one or more principals allowed to discover the endpoint service."
  type        = list(string)
  default     = null
}

variable "vpc_enable_flow_logs" {
  description = "Enable or disable VPC Flow logs"
  type        = bool
  default     = false
}

variable "vpc_flow_logs_lifecycle_rule_status" {
  description = "Define status of the S3 lifecycle rule. Possible options are enabled or disabled."
  type        = string
  default     = "Disabled"
}

variable "vpc_flow_logs_expiration_days" {
  description = "Define the days after which the VPC flow logs should be deleted"
  type        = number
  default     = 7
}

variable "lb_enable_private_access" {
  description = "Enable or disable the private access via PrivateLink to the GraphDB Cluster"
  type        = bool
  default     = false
}

variable "ami_id" {
  description = "(Optional) User-provided AMI ID to use with GraphDB instances. If you provide this value, please ensure it will work with the default userdata script (assumes latest version of Ubuntu LTS). Otherwise, please provide your own userdata script using the user_supplied_userdata_path variable."
  type        = string
  default     = null
}

variable "graphdb_version" {
  description = "GraphDB version"
  type        = string
  default     = "10.6.4"
  nullable    = false
}

variable "device_name" {
  description = "The device to which EBS volumes for the GraphDB data directory will be mapped."
  type        = string
  default     = "/dev/sdf"
}

variable "ebs_volume_type" {
  description = "Type of the EBS volumes, used by the GraphDB nodes."
  type        = string
  default     = "gp3"
}

variable "ebs_volume_size" {
  description = "The size of the EBS volumes, used by the GraphDB nodes."
  type        = number
  default     = 500
}

variable "ebs_volume_throughput" {
  description = "Throughput for the EBS volumes, used by the GraphDB nodes."
  type        = number
  default     = 250
}

variable "ebs_volume_iops" {
  description = "IOPS for the EBS volumes, used by the GraphDB nodes."
  type        = number
  default     = 8000
}

variable "ebs_kms_key_arn" {
  description = "KMS key used for ebs volume encryption."
  type        = string
  default     = "alias/aws/ebs"
}

variable "prevent_resource_deletion" {
  description = "Defines if applicable resources should be protected from deletion or not"
  type        = bool
  default     = true
}

variable "graphdb_license_path" {
  description = "Local path to a file, containing a GraphDB Enterprise license."
  type        = string
  default     = null
}

variable "graphdb_admin_password" {
  description = "Password for the 'admin' user in GraphDB."
  type        = string
  default     = null
  sensitive   = true
}

variable "graphdb_cluster_token" {
  description = "Cluster token used for authenticating the communication between the nodes."
  type        = string
  default     = null
  sensitive   = true
}

variable "route53_zone_dns_name" {
  description = "DNS name for the private hosted zone in Route 53"
  type        = string
  default     = "graphdb.cluster"

  validation {
    condition     = !can(regex(".*\\.local$", var.route53_zone_dns_name))
    error_message = "The DNS name cannot end with '.local'."
  }
}

# Monitoring

variable "deploy_monitoring" {
  description = "Enable or disable toggle for monitoring"
  type        = bool
  default     = false
}

variable "monitoring_route53_measure_latency" {
  description = "Enable or disable route53 function to measure latency"
  type        = bool
  default     = false
}

variable "monitoring_actions_enabled" {
  description = "Enable or disable actions on alarms"
  type        = bool
  default     = false
}

variable "monitoring_sns_topic_endpoint" {
  description = "Define an SNS endpoint which will be receiving the alerts via email"
  type        = string
  default     = null
}

variable "monitoring_sns_protocol" {
  description = "Define an SNS protocol that you will use to receive alerts. Possible options are: Email, Email-JSON, HTTP, HTTPS."
  type        = string
  default     = "email"
}

variable "monitoring_enable_detailed_instance_monitoring" {
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  type        = bool
  default     = false
}

variable "monitoring_endpoint_auto_confirms" {
  description = "Enable or disable endpoint auto confirm subscription to the sns topic"
  type        = bool
  default     = false
}

variable "monitoring_log_group_retention_in_days" {
  description = "Log group retention in days"
  type        = number
  default     = 30
}

variable "monitoring_route53_health_check_aws_region" {
  description = "Define the region in which you want the monitoring to be deployed. It is used to define where the Route53 Availability Check will be deployed, since if it is not specified it will deploy the check in us-east-1 and if you deploy in different region it will not find the dimensions."
  type        = string
  default     = "us-east-1"
}

# GraphDB overrides

variable "graphdb_properties_path" {
  description = "Path to a local file containing GraphDB properties (graphdb.properties) that would be appended to the default in the VM."
  type        = string
  default     = null
}

variable "graphdb_java_options" {
  description = "GraphDB options to pass to GraphDB with GRAPHDB_JAVA_OPTS environment variable."
  type        = string
  default     = null
}

# Logging

variable "deploy_logging_module" {
  description = "Enable or disable logging module"
  type        = bool
  default     = false
}

variable "logging_enable_bucket_replication" {
  description = "Enable or disable S3 bucket replication"
  type        = bool
  default     = false
}

variable "s3_enable_access_logs" {
  description = "Enable or disable access logs"
  type        = bool
  default     = false
}

variable "s3_access_logs_lifecycle_rule_status" {
  description = "Define status of the S3 lifecycle rule. Possible options are enabled or disabled."
  type        = string
  default     = "Disabled"
}

variable "s3_access_logs_expiration_days" {
  description = "Define the days after which the S3 access logs should be deleted."
  type        = number
  default     = 30
}

variable "s3_expired_object_delete_marker" {
  description = "Indicates whether Amazon S3 will remove a delete marker with no noncurrent versions. If set to true, the delete marker will be expired; if set to false the policy takes no action."
  type        = bool
  default     = true
}

variable "s3_mfa_delete" {
  description = "Enable MFA delete for either Change the versioning state of your bucket or Permanently delete an object version. Default is false. This cannot be used to toggle this setting but is available to allow managed buckets to reflect the state in AWS"
  type        = string
  default     = "Disabled"
}

variable "s3_versioning_enabled" {
  description = "Enable versioning. Once you version-enable a bucket, it can never return to an unversioned state. You can, however, suspend versioning on that bucket."
  type        = string
  default     = "Enabled"
}

variable "s3_abort_multipart_upload" {
  description = "Specifies the number of days after initiating a multipart upload when the multipart upload must be completed."
  type        = number
  default     = 7
}

variable "s3_enable_replication_rule" {
  description = "Enable or disable S3 bucket replication"
  type        = string
  default     = "Disabled"
}

variable "lb_access_logs_lifecycle_rule_status" {
  description = "Define status of the S3 lifecycle rule. Possible options are enabled or disabled."
  type        = string
  default     = "Disabled"
}

variable "lb_enable_access_logs" {
  description = "Enable or disable access logs for the NLB"
  type        = bool
  default     = false
}

variable "lb_access_logs_expiration_days" {
  description = "Define the days after which the LB access logs should be deleted."
  type        = number
  default     = 14
}

variable "bucket_replication_destination_region" {
  description = "Define in which Region should the bucket be replicated"
  type        = string
  default     = null
}

# ASG instance deployment options

variable "asg_enable_instance_refresh" {
  description = "Enables instance refresh for the GraphDB Auto scaling group. A refresh is started when any of the following Auto Scaling Group properties change: launch_configuration, launch_template, mixed_instances_policy"
  type        = bool
  default     = false
}

variable "asg_instance_refresh_checkpoint_delay" {
  description = "Number of seconds to wait after a checkpoint."
  type        = number
  default     = 3600
}

variable "graphdb_enable_userdata_scripts_on_reboot" {
  description = "(Experimental) Modifies cloud-config to always run user data scripts on EC2 boot"
  type        = bool
  default     = false
}
