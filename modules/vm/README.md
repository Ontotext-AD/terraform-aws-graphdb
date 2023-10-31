# Terraform Module:

This Terraform module configures IAM roles, EC2 instances, and associated security groups for running GraphDB with optional parameters and customization.

## Usage:

To use this module, include it in your Terraform configuration and provide the required and optional variables:
```hcl
module "graphdb_iam_ec2" {
  source = "path/to/module" 

  # Provide required and optional variables
  var.vpc_id                    = "vpc-01234567"
  var.resource_name_prefix      = "my-graphdb"
  var.iam_instance_profile      = "my-graphdb-instance-profile"
  var.iam_role_id               = "my-iam-role"
  var.userdata_script           = "#!/bin/bash\n# Your userdata script here"
  var.graphdb_subnets           = ["subnet-12345678", "subnet-87654321"]
  var.graphdb_target_group_arns = ["arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-target-group/abc123"]
  var.lb_subnets                = ["subnet-12345678", "subnet-87654321"]
  var.graphdb_version           = "4.0.0"
  var.instance_type             = "m5.large"

  # Optional variables
  var.ami_id                   = "ami-0123456789"
  var.allowed_inbound_cidrs    = ["10.0.0.0/16"]
  var.allowed_inbound_cidrs_ssh = ["192.168.1.0/24"]
  var.key_name                 = "my-key-pair"
  var.node_count               = 3
}
```

## Variables:

### Required Parameters:

`var.vpc_id` (string): VPC ID where GraphDB will be deployed.

`var.resource_name_prefix` (string): Resource name prefix used for tagging and naming AWS resources.

`var.iam_instance_profile` (string): IAM instance profile name to use for GraphDB instances.

`var.iam_role_id` (string): IAM role ID to attach permission policies to.

`var.userdata_script` (string): Userdata script for EC2 instance.

`var.graphdb_subnets` (list of strings): Private subnets where GraphDB will be deployed.

`var.graphdb_target_group_arns` (list of strings): Target group ARN(s) to register GraphDB nodes with.

`var.lb_subnets` (list of strings): The subnets used by the load balancer. If internet-facing use the public subnets, private otherwise.

`var.graphdb_version` (string): GraphDB version.

`var.instance_type` (string): EC2 instance type.

### Optional Parameters:

`var.ami_id` (string, default: null): AMI ID to use with GraphDB instances.

`var.allowed_inbound_cidrs` (list of strings, default: null): List of CIDR blocks to permit inbound traffic from to the load balancer.

`var.allowed_inbound_cidrs_ssh` (list of strings, default: null): List of CIDR blocks to give SSH access to GraphDB nodes.

`var.key_name` (string, default: null): Key pair to use for SSH access to instances.

`var.node_count` (number, default: 3): Number of GraphDB nodes to deploy in the Auto Scaling Group.

## What the Module Creates

This Terraform module creates the following AWS resources for GraphDB:

IAM roles and policies to grant necessary permissions to instances.
EC2 instances configured with userdata scripts for running GraphDB.
Security groups with rules for controlling inbound and outbound traffic to the instances.
Launch templates to define the instance configurations.
An Auto Scaling Group (ASG) for managing the EC2 instances.

## Outputs

The module provides three output values for reference in your Terraform configuration:

`asg_name` (string): Name of the Auto Scaling Group.

`launch_template_id` (string): ID of the launch template for the GraphDB ASG.

`graphdb_sg_id` (string): Security group ID of the GraphDB cluster.

## Example

Here's a complete example that demonstrates how to use the module:

```hcl
module "graphdb_iam_ec2" {
  source = "path/to/module" 

  var.vpc_id                    = "vpc-01234567"
  var.resource_name_prefix      = "my-graphdb"
  var.iam_instance_profile      = "my-graphdb-instance-profile"
  var.iam_role_id               = "my-iam-role"
  var.userdata_script           = "#!/bin/bash\n# Your userdata script here"
  var.graphdb_subnets           = ["subnet-12345678", "subnet-87654321"]
  var.graphdb_target_group_arns = ["arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-target-group/abc123"]
  var.lb_subnets                = ["subnet-12345678", "subnet-87654321"]
  var.graphdb_version           = "4.0.0"
  var.instance_type             = "m5.large"

  var.ami_id                   = "ami-0123456789"
  var.allowed_inbound_cidrs    = ["10.0.0.0/16"]
  var.allowed_inbound_cidrs_ssh = ["192.168.1.0/24"]
  var.key_name                 = "my-key-pair"
  var.node_count               = 3
}
```

This example demonstrates how to use the module to configure IAM roles, EC2 instances, and security groups for running GraphDB. Customize the variables to match your specific requirements.





