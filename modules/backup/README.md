# Terraform Module: AWS S3 Backup

This Terraform module creates an Amazon S3 bucket for storing backups, with server-side encryption, versioning, and access controls. It is designed for managing backups in an Amazon Web Services (AWS) environment.

## Usage

To use this module, include it in your Terraform configuration and provide the required variables:

```hcl
module "s3_backup" {
  source = "path/to/module"

}
```
## Inputs

```hcl
  variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources"
  type        = string
}

variable "iam_role_id" {
  description = "IAM role ID to attach permission policies to"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key to use for bucket encryption. If left empty, it will use the account's default for S3."
  type        = string
  default     = null
}
```

- `resource_name_prefix` (string): A prefix used for naming AWS resources and tagging the S3 bucket.
- `iam_role_id` (string): The IAM role ID to which permission policies will be attached.
- `kms_key_arn` (string, optional): The KMS key ARN to use for bucket encryption. If not provided, it will use the account's default KMS key for S3.

## Outputs

The module provides the following outputs for reference in your Terraform configuration:

- `bucket_name`: Name of the S3 bucket for storing GraphDB backups.
- `bucket_id`: ID of the S3 bucket for storing GraphDB backups.
- `bucket_arn`: ARN of the S3 bucket for storing GraphDB backups.

## Resources Created

The module creates the following AWS resources for your backup infrastructure:

- An S3 bucket with a unique name using the provided prefix.
- A public access block to prevent public access to the bucket.
- Server-side encryption using the specified KMS key (or the default account KMS key).
- Versioning enabled on the S3 bucket.
- A bucket policy that disallows non-TLS (Transport Layer Security) access to the bucket.
- An IAM role policy that grants necessary permissions for CRUD operations on the S3 bucket.

The module sets up your backup infrastructure with security and redundancy in mind, ensuring that your backups are stored securely and can be efficiently managed.

## Example

Here's a complete example of how to use the module:

```hcl
module "s3_backup" {
  source = "path/to/module"

  resource_name_prefix = "my-backup"
  iam_role_id          = "your-iam-role-id"
  kms_key_arn          = "your-kms-key-arn" 
}

```

This example creates an S3 bucket for backups, ensuring that it is secure, encrypted, and versioned. The bucket name is stored in the `backup_bucket_name` output for future reference.
