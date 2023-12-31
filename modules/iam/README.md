# Terraform Module: IAM Role and Instance Profile

This Terraform module creates an AWS Identity and Access Management (IAM) role and an instance profile that can be used for EC2 instances. It also supports the option to set a permissions boundary on the IAM role. The IAM role and instance profile can be customized with a user-supplied IAM role name.

## Usage

To use this module, include it in your Terraform configuration and provide the required and optional variables:

```hcl
module "iam_configuration" {
  source = "path/to/module"

  resource_name_prefix = "my-graphdb"
  permissions_boundary = "optional-iam-policy-arn" # Optional
  user_supplied_iam_role_name = "custom-iam-role-name" # Optional
}
```

- `resource_name_prefix` (string): A prefix used for naming AWS resources and tagging the IAM role and instance profile.

- `permissions_boundary` (string, optional): An IAM managed policy ARN that serves as a permissions boundary for the IAM role. This is optional and can be left as `null`.

- `user_supplied_iam_role_name` (string, optional): A user-provided IAM role name, which can be used for the instance profile provided to the AWS launch configuration. The minimum permissions must match the defaults generated by the IAM submodule for cloud auto-join and auto-unseal. This is optional and can be left as `null`.

## Variables

### Required Parameters

- `resource_name_prefix` (string): Resource name prefix used for naming AWS resources.

### Optional Parameters

- `permissions_boundary` (string, optional): IAM managed policy ARN to serve as a permissions boundary for the IAM role. Default is `null`.

- `user_supplied_iam_role_name` (string, optional): User-provided IAM role name. Default is `null`.

## What the Module Creates

The module creates an IAM role with the option to set a permissions boundary and an instance profile that can be used for EC2 instances.

## Outputs

The module provides two output values for reference in your Terraform configuration:

- `iam_instance_profile`: Instance profile to use for EC2.

- `iam_role_id`: IAM role ID to use for policies.

## Example

Here's a complete example that demonstrates how to use the module:

```hcl
module "iam_configuration" {
  source = "path/to/module"

  resource_name_prefix = "my-graphdb"
  permissions_boundary = "optional-iam-policy-arn" # Optional
  user_supplied_iam_role_name = "custom-iam-role-name" # Optional
}

output "instance_profile" {
  value = module.iam_configuration.iam_instance_profile
}
```

This example creates an IAM role and an instance profile. The instance profile can be used for EC2 instances, and the IAM role has an optional permissions boundary. The `instance_profile` output value contains the name of the instance profile for future reference.
