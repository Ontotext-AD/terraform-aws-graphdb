# GraphDB AWS Terraform Module

This Terraform module allows you to provision an GraphDB cluster within a Virtual Private Cloud (VPC). The module provides a flexible way to configure the cluster and the associated VPC components.

—
## Prerequisites

Before you begin using this Terraform module, ensure you have the following prerequisites:

- **Terraform Installed**: You should have Terraform installed on your local machine. You can download Terraform from the [official website](https://www.terraform.io/downloads.html).

- **AWS Credentials**: Ensure that you have AWS credentials configured on your machine. You can configure AWS access keys and secret keys using the [AWS CLI](https://aws.amazon.com/cli/).

- **Terraform AWS Provider Configuration**: Configure the AWS provider in your Terraform project. You can add your AWS access and secret keys as environment variables or use other methods for provider configuration.

- **Terraform Configuration File**: Create a new Terraform configuration file in your project, and use this module by specifying its source.

—

## Usage

To use this module, follow these steps:

1. Clone the repository to your local machine:

   ```shell
   git clone https://github.com/Ontotext-AD/terraform-aws-graphdb.git
   ```

2. Navigate to the module directory:

   ```shell
   cd terraform-aws-graphdb/modules/aws-graphdb-cluster
   ```

3. Create a new Terraform configuration in your project, and use this module by specifying its source:

   ```hcl
   module "graphdb_cluster" {
     source = "../../modules/aws-graphdb-cluster"

     # Define your configuration variables here, such as cluster size, VPC settings, and other parameters.


   }

   # Configure the required variables for the module.
   ```

4. Initialize your Terraform workspace and apply the changes:

  ```shell
    terraform init
    terraform plan
  ```

5. Review and confirm the changes when prompted and apply if everything is okay.

  ```shell
    terraform apply
  ```





## Configuration

This README provides more detailed information about the important variables and how to configure them for the Terraform AWS GraphDB module. Please ensure that you adapt the configuration to match your specific use case and requirements.

### Important Variables (Inputs)

The following are the important variables you should configure when using this module:

- `vpc_id`: The ID of the Virtual Private Cloud (VPC) where you want to create the AWS GraphDB cluster. This is a required variable.

- `instance_type`: The instance type for the GDB cluster nodes. This should match your performance and cost requirements.

- `cluster_size`: The number of instances in the cluster. Recommended is 3, 5 or 7 in order to have consensus according to the [RAFT algorithm](https://raft.github.io/). 

- `subnet_ids`: A list of subnet IDs in your VPC to place the Neptune instances. Ensure that these subnets have proper route tables and security groups configured.

- `security_group_ids`: A list of security group IDs to associate with the instances for network security.






## Examples

This repository includes usage examples in the `examples/` directory, such as:

- [VPC with Multiple Availability Zones](./examples/vpc-with-multiple-az): Demonstrates creating a VPC with multiple Availability Zones and provisioning an AWS GraphDB cluster.

Here's an example of how to configure the module in your Terraform project:

#### Example Configuration

```hcl
variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}


variable "azs" {
  description = "Availability zones to use in AWS region"
  type        = list(string)
  default = [	"us-east-1a",
    			"us-east-1b",
  			"us-east-1c", ]
}


variable "resource_name_prefix" {
  description = "Prefix for resource names"
  type        = string
}


variable "graphdb_license_path" {
  description = “Path to your license file” 
  type        = string
  default 	   = "$PATH/$TO/Your/License.license"


}


variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}


variable "ami_id" {
  description = "AMI id"
  type        = string
  default     = null
}
#from Module VM
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = null
}


variable "graphdb_version" {
  description = "GraphDB version"
  type        = string
  default     = null
}
```

Ensure that you adjust the values of the variables to match your specific requirements.

## Modules

#### [Backup](modules/backup/README.md)
This Terraform module creates an Amazon S3 bucket for storing backups.

#### [Config](modules/config/README.md)
This Terraform module creates AWS Systems Manager (SSM) parameters for managing sensitive data and configuration settings used by GraphDB in an AWS environment.

#### [DNS](modules/dns/README.md)
This Terraform module creates a private hosted zone in Amazon Route 53 for DNS resolution in your Virtual Private Cloud (VPC).

#### [IAM](modules/iam/README.md)
This Terraform module creates an AWS Identity and Access Management (IAM) role and an instance profile that can be used for EC2 instances. It also supports the option to set a permissions boundary on the IAM role. 

#### [Load Balancer](modules/load_balancer/README.md)
This Terraform module sets up an AWS Elastic Load Balancer (Network Load Balancer) with optional TLS listeners. The module is designed to be flexible and customizable by accepting various input variables to tailor the NLB configuration to your specific requirements.

#### [User Data](modules/user_data/README.md)
This Terraform module configures an AWS EC2 instance for running GraphDB with various optional parameters and user-supplied userdata.

#### [VM](modules/vm/README.md)
This Terraform module configures IAM roles, EC2 instances, and associated security groups for running GraphDB with optional parameters and customization.


## Contributing
Check out the contributors guide [CONTRIBUTING.md](CONTRIBUTING.md).


## License

This code is released under the Apache 2.0 License. See [LICENSE](LICENSE) for more details.

