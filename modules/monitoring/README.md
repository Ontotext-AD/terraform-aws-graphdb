# GraphDB AWS Monitoring Module

This module adds metrics scraping from GraphDB cluster to Cloudwatch.

## Usage

To use this module, include it in your Terraform configuration and provide the required and optional variables:
```hcl
module "monitoring" {
  source = "path/to/module"

  # Provide required and optional variables
  resource_name_prefix = var.resource_name_prefix
  actions_enabled = var.actions_enabled
  sns_topic_endpoint = var.sns_topic_endpoint
  endpoint_auto_confirms = var.endpoint_auto_confirms
  sns_protocol = var.sns_protocol
  log_group_retention_in_days = var.log_group_retention_in_days

  aws_region = var.aws_region
  web_test_availability_request_url = module.load_balancer.lb_dns_name
  measure_latency = var.measure_latency
}
```

## Variables

### Required Parameters

`al_low_memory_warning_threshold` (number): The threshold which needs to be set for the memory alarm to be triggered. Default is 90.

`var.resource_name_prefix` (string): Resource name prefix used for tagging and naming AWS resources.

`var.actions_enabled` (bool): If you want to enable actions on the alarms for example to send notifications via sns.

`sns_topic_endpoint` (string): Used to specify the endpoint which will receive the alerts via sns.

`endpoint_auto_confirms` (bool): Used to enable or disable automatic confirmation for the sns endpoint.

`sns_protocol` (string): Used to set the sns protocol which will be used to receive alarms. Possible options are: email, email-json, http, https.

`log_group_retention_in_days` (number): Used to define how long the logs to be retained.

`aws_region` (string): Used to specify the region in which the monitoring will be deployed.

`web_test_availability_request_url` (string): Used to define the url which will be tested for the availability check.

`measure_latency` (bool): Enable or disable measure latency check for the Route 53 check.

`route53_http_string_type` (string): Define http string type for the route 53 health check. Possible options are: HTTP, HTTPS, HTTP_STR_MATCH, HTTPS_STR_MATCH, TCP, CALCULATED, CLOUDWATCH_METRIC and RECOVERY_CONTROL. Default is HTTP_STR_MATCH.

`parameter_store_ssm_parameter_type` (string) : Define the type of the parameter store for the ssm parameter for the cloudwatch agent. Default is string.

`parameter_store_ssm_parameter_tier` (string) : Define parameter store ssm parameter tier. Possible options are: Standard, Advanced. Default is Advanced because of the size of the config file.

`web_test_port` (number) : Define which HTTP port to use for the web test availability. Default is 80.

`period` (number) :  The length of time to use to evaluate the metric or expression to create each individual data point for an alarm. It is expressed in seconds. Default is 60.

`evalutation_periods` (number) : The number of the most recent periods, or data points, to evaluate when determining alarm state. Default is 1.

`web_test_timeout` (number) : Seconds until this WebTest will timeout and fail. Valid options are 5-10, Default is 10.

`web_test_frequency` (number) : Interval in seconds between tests. Valid options are 5-30. Default is 30.

`web_test_availability_content_match` (string) : HTTP Content match for web test availability. Default is : "\"nodeState\":\"LEADER\""

`web_test_availability_path` (string) : Path for the web test to be used. Default is: /rest/cluster/node/status

`web_availability_regions` list(string): Define regions from which you want to test. Defaults are : ["us-east-1", "us-west-1", "ap-southeast-1", "eu-west-1", "sa-east-1"]

## What the Module Creates

This Terraform module creates an AWS Cloudwatch Dasbhoard, Log Group and alarms for CPU, Memory Utilization, GraphDB Nodes Disconnected, Availability Check and 2 alarms based on log messages:

## Good to know

If you choose to deploy in region different than us-east-1 you should know that the route53 health check will be created in us-east-1 since Route53 is a global service, not a regional service. Because of that Route53 publishes metrics only in us-east-1. Since alarms are not cross-regional, the alarm will be created in us-east-1 as well. You can read more [here[(https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Cross-Account-Cross-Region.html)].
