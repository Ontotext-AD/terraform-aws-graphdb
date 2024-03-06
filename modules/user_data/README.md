# Terraform Module:

This Terraform module configures an AWS EC2 instance for running GraphDB with various optional parameters and user-supplied userdata.

## Usage:

To use this module, include it in your Terraform configuration and provide the required and optional variables:
```hcl
module "graphdb_instance" {
  source = "path/to/module"

  # Provide required and optional variables
  var.aws_region             = "us-east-1"
  var.resource_name_prefix  = "my-graphdb-instance"
  var.device_name            = "/dev/sdh"
  var.backup_schedule        = "0 0 * * *"
  var.backup_bucket_name     = "my-backup-bucket"
  var.ebs_volume_type        = "gp3"
  var.ebs_volume_size        = 100
  var.ebs_volume_throughput  = 150
  var.ebs_volume_iops        = 3000
  var.ebs_kms_key_arn        = "arn:aws:kms:us-east-1:123456789012:key/abcd1234"
  var.zone_dns_name          = "myprivatedns.local"
  var.zone_id                = "Z1234567890"
  var.instance_type          = "m5.large"

  # Optional variables
  var.user_supplied_userdata_path = "path/to/userdata_script.sh"
  var.backup_retention_count     = 7
}
```

## Variables:

### Required Parameters:

`var.aws_region` (string): AWS region where GraphDB is being deployed.

`var.resource_name_prefix` (string): Resource name prefix used for tagging and naming AWS resources.

`var.device_name` (string): The device to which EBS volumes for the GraphDB data directory will be mapped.

`var.backup_schedule` (string): Cron expression for the backup job.

`var.backup_bucket_name` (string): Name of the S3 bucket for storing GraphDB backups.

`var.ebs_volume_type` (string): Type of the EBS volumes used by the GraphDB nodes.

`var.ebs_volume_size` (number): The size of the EBS volumes used by the GraphDB nodes.

`var.ebs_volume_throughput` (number): Throughput for the EBS volumes used by the GraphDB nodes.

`var.ebs_volume_iops` (number): IOPS for the EBS volumes used by the GraphDB nodes.

`var.ebs_kms_key_arn` (string): KMS key used for EBS volume encryption.

`var.zone_dns_name` (string): DNS name for the private hosted zone in Route 53.

`var.zone_id` (string): Route 53 private hosted zone ID.

`var.instance_type` (string): EC2 instance type.

### Optional Parameters:

`var.user_supplied_userdata_path` (string, default: null): File path to custom userdata script supplied by the user.

`var.backup_retention_count` (number, default: 7): Number of backups to keep.

## What the Module Creates

This Terraform module creates an AWS EC2 instance configured for running GraphDB with the following components and settings:

An EC2 instance with specifications based on the specified var.instance_type.
EBS volumes for the GraphDB data directory with the specified type, size, throughput, IOPS, and encryption using the provided KMS key.
A user data script to initialize and start GraphDB, which can be customized using the var.user_supplied_userdata_path variable or a default template.
A backup job schedule using the specified var.backup_schedule.
Configuration for backing up GraphDB to the specified S3 bucket (var.backup_bucket_name).
Private hosted zone DNS settings for Route 53 using the specified var.zone_dns_name and var.zone_id.
The module combines these components and settings to create a fully configured AWS EC2 instance ready to run GraphDB, with the flexibility to customize various parameters to suit your requirements.

## Outputs

The module provides two output values for reference in your Terraform configuration:
`graphdb_userdata_base64_encoded` (string): Base64-encoded user data for the GraphDB instance.

## Example

Here's a complete example that demonstrates how to use the module:

```hcl
module "graphdb_instance" {
  source = "path/to/module" # Replace with the actual source

  var.aws_region             = "us-east-1"
  var.resource_name_prefix  = "my-graphdb-instance"
  var.device_name            = "/dev/sdh"
  var.backup_schedule        = "0 0 * * *"
  var.backup_bucket_name     = "my-backup-bucket"
  var.ebs_volume_type        = "gp3"
  var.ebs_volume_size        = 100
  var.ebs_volume_throughput  = 150
  var.ebs_volume_iops        = 3000
  var.ebs_kms_key_arn        = "arn:aws:kms:us-east-1:123456789012:key/abcd1234"
  var.zone_dns_name          = "myprivatedns.local"
  var.zone_id                = "Z1234567890"
  var.instance_type          = "m5.large"

  var.user_supplied_userdata_path = "path/to/userdata_script.sh"
  var.backup_retention_count     = 7
}
```
This example demonstrates how to use the module to configure an AWS EC2 instance for running GraphDB. Adjust the variables as needed for your specific use case.
