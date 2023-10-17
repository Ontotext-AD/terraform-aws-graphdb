# Terraform Module: AWS Systems Manager Parameters

This Terraform module creates AWS Systems Manager (SSM) parameters for managing sensitive data and configuration settings used by GraphDB in an AWS environment. The SSM parameters are securely stored and can be easily referenced in other resources or scripts.

## Usage

To use this module, include it in your Terraform configuration and provide the required variables:

```hcl
module "graphdb_parameters" {
  source = "path/to/module"

  resource_name_prefix = "my-graphdb"
  graphdb_admin_password = "your-admin-password"
  graphdb_cluster_token = "your-cluster-token"
  graphdb_license_path = "local/license/path" # Optional
  graphdb_lb_dns_name = "your-lb-dns-name"
}
```

- `resource_name_prefix` (string): A prefix used for naming SSM parameters and for tagging AWS resources. Replace `"my-graphdb"` with your desired prefix.

- `graphdb_admin_password` (string): The password for the 'admin' user in GraphDB. It should be a sensitive string. Replace `"your-admin-password"` with the actual password.

- `graphdb_cluster_token` (string): The cluster token used for authenticating communication between GraphDB nodes. It should be a sensitive string. Replace `"your-cluster-token"` with the actual token.

- `graphdb_license_path` (string, optional): The local file path to a GraphDB Enterprise license. This variable is optional, and you can leave it as `null` or provide the path to your license file.

- `graphdb_lb_dns_name` (string): The DNS name of the load balancer for GraphDB nodes. Replace `"your-lb-dns-name"` with the actual DNS name.

## Variables

### REQUIRED Parameters

- `resource_name_prefix` (string): Resource name prefix used for tagging and naming AWS resources.

### OPTIONAL Parameters

- `graphdb_admin_password` (string): Password for the 'admin' user in GraphDB. It has a default value of `"s3cret"` but should be set to your desired admin password.

- `graphdb_cluster_token` (string): Cluster token used for authenticating communication between GraphDB nodes. It has a default value of `"s3cret"` but should be set to your desired token.

- `graphdb_license_path` (string, optional): Local path to a file containing a GraphDB Enterprise license. It has a default value of `null`, indicating it's optional. Provide the path to your license file if applicable.

- `graphdb_lb_dns_name` (string): The DNS name of the load balancer for GraphDB nodes. Set this variable to your specific DNS name.

## Versions

This module requires Terraform version 1.4.0 or higher. It also specifies the required version of the AWS provider.

## What the Module Creates

The module creates SSM parameters with the specified names and values for storing sensitive information and configuration settings used by GraphDB.

## Example

Here is a complete example that demonstrates how to use the module:

```hcl
module "graphdb_parameters" {
  source = "path/to/module"

  resource_name_prefix = "my-graphdb"
  graphdb_admin_password = "my-admin-password"
  graphdb_cluster_token = "my-cluster-token"
  graphdb_license_path = "local/path/to/license/file" # Optional
  graphdb_lb_dns_name = "my-lb-dns-name"
}
```

This example creates SSM parameters for storing sensitive information and configuration settings for GraphDB. It securely manages passwords, tokens, and other GraphDB parameters.
