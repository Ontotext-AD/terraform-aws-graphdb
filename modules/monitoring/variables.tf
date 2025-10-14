variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources"
  type        = string
}

variable "aws_region" {
  description = "Define the region in which the monitoring will be deployed"
  type        = string
}

variable "route53_availability_regions" {
  description = "Define regions from which you want to test"
  type        = list(string)
  default     = ["us-east-1", "us-west-1", "ap-southeast-1", "eu-west-1", "sa-east-1"]
}

variable "route53_availability_request_url" {
  description = "Define the request url which the health check will monitor"
  type        = string
}

variable "route53_availability_frequency" {
  description = "Interval in seconds between tests. Valid options are 5-30. Default is 30."
  type        = number
  default     = 30
}

variable "route53_availability_timeout" {
  description = "Seconds until this WebTest will timeout and fail. Valid options are 5-10, Default is 10."
  type        = number
  default     = 10
}

variable "cloudwatch_evaluation_periods" {
  description = "The number of the most recent periods, or data points, to evaluate when determining alarm state."
  type        = number
  default     = 1
}

variable "cloudwatch_period" {
  description = "The length of time to use to evaluate the metric or expression to create each individual data point for an alarm. It is expressed in seconds."
  type        = number
  default     = 60
}

variable "route53_availability_measure_latency" {
  description = "Enable or disable latency measure feature for Route 53 Health Check."
  type        = bool
}

variable "sns_topic_endpoint" {
  description = "Define an SNS endpoint which will be receiving the alerts via email"
  type        = string
}

variable "sns_protocol" {
  description = "Define an SNS protocol that you will use to receive alerts. Possible options are: Email, Email-JSON, HTTP, HTTPS."
  type        = string
}

variable "sns_endpoint_auto_confirms" {
  description = "Enable or disable endpoint auto confirm subscription to the sns topic"
  type        = bool
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Log Group retention in days."
  type        = number
}

variable "route53_availability_port" {
  description = "Which HTTP port to use for the web availability tests"
  type        = number
  default     = 80
}

variable "route53_availability_http_string_type" {
  description = "HTTP string type: Valid values are HTTP, HTTPS, HTTP_STR_MATCH, HTTPS_STR_MATCH, TCP, CALCULATED, CLOUDWATCH_METRIC and RECOVERY_CONTROL"
  type        = string
}

variable "ssm_parameter_store_ssm_parameter_tier" {
  description = "Define parameter store tier for the cloudwatch agent. Possible values are: Standard, Advanced. Default is Advanced, because of the size of the config."
  type        = string
  default     = "Advanced"
}

variable "ssm_parameter_store_ssm_parameter_type" {
  description = "Define parameter store ssm parameter type for the cloudwatch agent config"
  type        = string
  default     = "SecureString"
}

variable "route53_availability_check_region" {
  description = "Define route53 health check region"
  type        = string
}

# KMS Encryption for SNS topics:

variable "sns_cmk_description" {
  description = "Description of the Key to be created"
  type        = string
}

variable "deletion_window_in_days" {
  description = "The waiting period, specified in number of days for AWS to delete the KMS key(Between 7 and 30)."
  type        = number
}

variable "key_spec" {
  description = "Specification of the Key."
  type        = string
}

variable "key_enabled" {
  description = "Specifies whether the key is enabled."
  type        = bool
}

variable "rotation_enabled" {
  description = "Specifies whether key rotation is enabled."
  type        = bool
}

variable "cmk_key_alias" {
  description = "The alias for the CMK key."
  type        = string
}

variable "enable_sns_kms_key" {
  description = "Enable CMK for encryption. If false, use AWS managed key."
  type        = bool
}

variable "sns_key_admin_arn" {
  description = "ARN of the role or user who will have administrative access to the SNS KMS key"
  type        = string
  default     = ""
}

variable "sns_external_kms_key" {
  description = "ARN of the external KMS key that will be used for encryption of SNS topics"
  type        = string
  default     = ""
}

variable "sns_default_kms_key" {
  description = "ARN of the default KMS key that will be used for encryption of SNS topics"
  type        = string
}

variable "sns_kms_key_arn" {
  description = "ARN of the KMS key"
  type        = string
}

variable "parameter_store_kms_key_arn" {
  description = "ARN of the parameter store KMS Key"
  type        = string
}

variable "graphdb_node_count" {
  description = "Number of GraphDB nodes to deploy in ASG"
  type        = number
}

variable "route53_availability_http_port" {
  description = "Define the HTTP port for the Route53 availability check"
  type        = number
  default     = 80
}

variable "route53_availability_https_port" {
  description = "Define the HTTPS port for the Route53 availability check"
  type        = number
  default     = 443
}

variable "route53_zone_dns_name" {
  description = "DNS name for the private hosted zone in Route 53"
  type        = string
}

variable "lb_tls_certificate_arn" {
  description = "ARN of the TLS certificate, imported in ACM, which will be used for the TLS listener on the load balancer."
  type        = string
}

variable "lb_dns_name" {
  description = "Define the LB DNS name"
  type        = string
}

variable "enable_availability_tests" {
  description = "Enable Route 53 availability tests and alarms"
  type        = bool
}

variable "cloudwatch_cpu_utilization_threshold" {
  description = "Alarm threshold for Cloudwatch CPU Utilization"
  type        = number
}

variable "graphdb_memory_utilization_threshold" {
  description = "Alarm threshold for GraphDB Memory Utilization"
  type        = number
}

variable "cmk_availability_key_alias" {
  description = "CMK Key Alias for the availability SNS topic"
  type        = string
}
