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

`al_low_memory_warning_threshold` (number): The threshold which needs to be set for the memory alarm to be triggered.

`var.resource_name_prefix` (string): Resource name prefix used for tagging and naming AWS resources.

`var.actions_enabled` (bool): If you want to enable actions on the alarms for example to send notifications via sns.

`sns_topic_endpoint` (string): Used to specify the endpoint which will receive the alerts via sns.

`endpoint_auto_confirms` (bool): Used to enable or disable automatic confirmation for the sns endpoint.

`sns_protocol` (string): Used to set the sns protocol which will be used to receive alarms. Possible options are: email, email-json, http, https.

`log_group_retention_in_days` (number): Used to define how long the logs to be retained.

`aws_region` (string): Used to specify the region in which the monitoring will be deployed.

`web_test_availability_request_url` (string): Used to define the url which will be tested for the availability check.

`measure_latency` (bool): Enable or disable measure latency check for the Route 53 check.

## What the Module Creates

This Terraform module creates an AWS Cloudwatch Dasbhoard, Log Group and alarms for CPU, Memory Utilization, GraphDB Nodes Disconnected, Availability Check and 2 alarms based on log messages:
