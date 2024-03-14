variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources"
  type        = string
}

variable "aws_region" {
  description = "Define the region in which the monitoring will be deployed"
  type        = string
}

variable "web_availability_regions" {
  description = "Define regions from which you want to test"
  type        = list(string)
  default     = ["us-east-1", "us-west-1", "ap-southeast-1", "eu-west-1", "sa-east-1"]
}

variable "web_test_availability_request_url" {
  description = "Define the request url which the health check will monitor"
  type        = string
}

variable "actions_enabled" {
  description = "Enable or disable actions on alarms"
  type        = bool
}

variable "web_test_availability_path" {
  description = "Path for the web test to be used"
  type        = string
  default     = "/rest/cluster/node/status"
}

variable "web_test_availability_content_match" {
  description = "HTTP Content match for web test availability"
  type        = string
  default     = "\"nodeState\":\"LEADER\""
}

variable "web_test_frequency" {
  description = "Interval in seconds between tests. Valid options are 5-30. Default is 30."
  type        = number
  default     = 30
}

variable "web_test_timeout" {
  description = "Seconds until this WebTest will timeout and fail. Valid options are 5-10, Default is 10."
  type        = number
  default     = 10
}

variable "evaluation_periods" {
  description = "The number of the most recent periods, or data points, to evaluate when determining alarm state."
  type        = number
  default     = 1
}

variable "period" {
  description = "The length of time to use to evaluate the metric or expression to create each individual data point for an alarm. It is expressed in seconds."
  type        = number
  default     = 60
}

variable "measure_latency" {
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

variable "endpoint_auto_confirms" {
  description = "Enable or disable endpoint auto confirm subscription to the sns topic"
  type        = bool
}

variable "log_group_retention_in_days" {
  description = "Log Group retention in days."
  type        = number
}

variable "al_low_memory_warning_threshold" {
  description = "Percentage of available used heap memory to monitor for"
  type        = number
  default     = 90
}

variable "web_test_port" {
  description = "Which HTTP port to use for the web availability tests"
  type        = number
  default     = 80
}

variable "route53_http_string_type" {
  description = "HTTP string type: Valid values are HTTP, HTTPS, HTTP_STR_MATCH, HTTPS_STR_MATCH, TCP, CALCULATED, CLOUDWATCH_METRIC and RECOVERY_CONTROL"
  type        = string
  default     = "HTTP_STR_MATCH"
}

variable "parameter_store_ssm_parameter_tier" {
  description = "Define parameter store tier for the cloudwatch agent. Possible values are: Standard, Advanced. Default is Advanced, because of the size of the config."
  type        = string
  default     = "Advanced"
}

variable "parameter_store_ssm_parameter_type" {
  description = "Define parameter store ssm parameter type for the cloudwatch agent config"
  type        = string
  default     = "String"
}

