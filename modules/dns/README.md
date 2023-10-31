# Terraform Module: AWS Route 53 DNS Configuration

This Terraform module creates a private hosted zone in Amazon Route 53 for DNS resolution in your Virtual Private Cloud (VPC). It also configures permissions for updating the DNS records within the hosted zone.

## Usage

To use this module, include it in your Terraform configuration and provide the required variables:

```hcl
module "dns_configuration" {
  source = "path/to/module"

  vpc_id = "your-vpc-id"
  resource_name_prefix = "my-graphdb"
  zone_dns_name = "your.dns.name"
  iam_role_id = "your-iam-role-id"
}
```

- `vpc_id` (string): The VPC ID where GraphDB will be deployed. Replace `"your-vpc-id"` with the actual VPC ID.

- `resource_name_prefix` (string): A prefix used for naming AWS resources and tagging the hosted zone.

- `zone_dns_name` (string): The DNS name for the private hosted zone in Route 53. Replace `"your.dns.name"` with your desired DNS name.

- `iam_role_id` (string): The IAM role ID to which permission policies for Route 53 updates will be attached. Replace `"your-iam-role-id"` with the actual IAM role ID.

## Variables

### Required Parameters

- `vpc_id` (string): VPC ID where GraphDB will be deployed.

- `resource_name_prefix` (string): Resource name prefix used for naming AWS resources.

- `zone_dns_name` (string): DNS name for the private hosted zone in Route 53.

- `iam_role_id` (string): IAM role ID to attach permission policies to.

## What the Module Creates

The module creates a private hosted zone in Amazon Route 53 and sets permissions for the specified IAM role to allow updating DNS records within the hosted zone.

## Outputs

The module provides an output value that can be referenced in your Terraform configuration:

- `zone_id`: The ID of the private hosted zone for GraphDB DNS resolving.

## Example

Here's a complete example that demonstrates how to use the module:

```hcl
module "dns_configuration" {
  source = "path/to/module"

  vpc_id = "your-vpc-id"
  resource_name_prefix = "my-graphdb"
  zone_dns_name = "your.dns.name"
  iam_role_id = "your-iam-role-id"
}

output "dns_zone_id" {
  value = module.dns_configuration.zone_id
}
```

This example creates a private hosted zone for DNS resolution in a specified VPC, sets permissions for updating DNS records, and stores the zone ID in the `dns_zone_id` output for future reference.
