# Terraform Module:

This Terraform module sets up an AWS Elastic Load Balancer (Network Load Balancer) with optional TLS listeners. The module is designed to be flexible and customizable by accepting various input variables to tailor the NLB configuration to your specific requirements.

## Usage:

To use this module, include it in your Terraform configuration and provide the required and optional variables:
```hcl
module "graphdb_lb" {
  source = "path/to/module"

  # Provide required and optional variables
  var.resource_name_prefix         = "my-application"
  var.lb_tls_certificate_arn       = "arn:aws:acm:us-east-1:123456789012:certificate/abc123"
  var.lb_internal                  = false
  var.lb_subnets                   = ["subnet-12345678", "subnet-87654321"]
  var.lb_enable_deletion_protection = true
  var.lb_security_groups            = ["sg-abcdef01"]
  var.vpc_id                       = "vpc-01234567"
  var.lb_deregistration_delay      = 300
  var.lb_healthy_threshold          = 3
  var.lb_unhealthy_threshold        = 3
  var.lb_health_check_path          = "/health"
  var.lb_health_check_interval      = 30
  var.lb_tls_policy                 = "ELBSecurityPolicy-2016-08"
}
```

## Variables:

### Required Parameters:

`var.resource_name_prefix`(string): A prefix used to form the name of the load balancer.
`var.lb_tls_certificate_arn`(string): The ARN of the TLS certificate to be used for HTTPS. Set to null if TLS is not required.
`var.vpc_id`(string): Identifier of the VPC where GraphDB will be deployed.

### Optional Parameters:

`var.lb_subnets`(list): Collection of subnet identifiers where the load balancer will be deployed.

`var.lb_security_groups`(list): Security groups to assign when the LB is internal. Defaults to an empty list.

`var.lb_internal` (bool): Whether the load balancer will be internal or internet-facing. Defaults to false.

`var.lb_deregistration_delay` (string): Amount of time, in seconds, for GraphDB LB target group to wait before changing the state of a deregistering target from draining to unused. Defaults to `300`.

`var.lb_healthy_threshold` (number): Number of consecutive health check successes required to consider a GraphDB target healthy. Defaults to `3`.

`var.lb_unhealthy_threshold` (number): Number of consecutive health check failures required before considering a GraphDB target unhealthy. Defaults to `3`.

`var.lb_health_check_path` (string): The endpoint to check for GraphDB's health status. Defaults to `"/rest/cluster/node/status"`.

`var.lb_health_check_interval` (number): Interval in seconds for checking the target group health check. `Defaults to 10`.

`var.lb_enable_deletion_protection` (bool): Defines if the load balancer should be protected from deletion or not. Defaults to `true`.

### TLS Parameters:

`var.lb_tls_certificate_arn` (string): ARN of the TLS certificate, imported in ACM, which will be used for the TLS listener on the load balancer. Defaults to `null`.

`var.lb_tls_policy` (string): TLS security policy on the listener. Defaults to `"ELBSecurityPolicy-TLS13-1-2-2021-06"`.

## What the Module Creates

An AWS Network Load Balancer (NLB) named using the specified var.resource_name_prefix.
An AWS target group named using the same name as the NLB.
Optional HTTP and HTTPS listeners (depending on the presence of var.lb_tls_certificate_arn) for the NLB.

## Outputs

The module provides four output values for reference in your Terraform configuration:
`lb_arn` (string): ARN of the GraphDB load balancer.

`lb_dns_name` (string): DNS name of the GraphDB load balancer.

`lb_zone_id` (string): Route 53 zone ID of the GraphDB load balancer.

`lb_target_group_arn` (string): Target group ARN of the registered GraphDB nodes.

## Example

Here's a complete example that demonstrates how to use the module:
```hcl
module "graphdb_lb" {
  source = "path/to/module" # Replace with the actual source

  var.resource_name_prefix         = "my-application"
  var.lb_tls_certificate_arn       = "arn:aws:acm:us-east-1:123456789012:certificate/abc123"
  var.lb_internal                  = false
  var.lb_subnets                   = ["subnet-12345678", "subnet-87654321"]
  var.lb_enable_deletion_protection = true
  var.lb_security_groups            = ["sg-abcdef01"]
  var.vpc_id                       = "vpc-01234567"
  var.lb_deregistration_delay      = 300
  var.lb_healthy_threshold          = 3
  var.lb_unhealthy_threshold        = 3
  var.lb_health_check_path          = "/health"
  var.lb_health_check_interval      = 30
  var.lb_tls_policy                 = "ELBSecurityPolicy-2016-08"
}
```
This example demonstrates how to use the module to create an AWS Network Load Balancer with TLS listener support. Adjust the variables as needed for your specific use case.
