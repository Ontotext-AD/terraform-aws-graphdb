# GraphDB AWS Terraform Module

This Terraform module allows you to provision an GraphDB cluster within a Virtual Private Cloud (VPC). The module
provides a flexible way to configure the cluster and the associated VPC components. It implements the GraphDB reference
architecture. Check the official [documentation](https://graphdb.ontotext.com/documentation/11.0/aws-deployment.html)
for more details.

## Table of contents

- [About GraphDB](#about-graphdb)
- [Features](#features)
- [Versioning](#versioning)
- [Prerequisites](#prerequisites)
- [Inputs](#inputs)
- [Usage](#usage)
- [Examples](#examples)
- [Updating configurations on an active deployment](#updating-configurations-on-an-active-deployment)
- [Local Development](#local-development)
- [Release History](#release-history)
- [Contributing](#contributing)
- [License](#license)

## About GraphDB

<p align="center">
  <a href="https://www.ontotext.com/products/graphdb/">
    <picture>
      <img src="https://www.ontotext.com/wp-content/uploads/2022/09/Logo-GraphDB.svg" alt="GraphDB logo" title="GraphDB"
      height="75">
    </picture>
  </a>
</p>

Ontotext GraphDB is a highly efficient, scalable and robust graph database with RDF and SPARQL support. With excellent
enterprise features,
integration with external search applications, compatibility with industry standards, and both community and commercial
support, GraphDB is the
preferred database choice of both small independent developers and big enterprises.

## Features

The module provides the building blocks of configuring, deploying and provisioning a highly available cluster of GraphDB
across multiple availability zones using EC2 Autoscaling Group. Key features of the module include:

- EC2 Autoscaling Group
- Network Load Balancer
- NAT Gateway for outbound connections
- Route53 Private Hosted Zone for internal GraphDB cluster communication
- IAM Policies and roles
- VPC
- Monitoring
- Backup
- and many more

## Versioning

The Terraform module follows the Semantic Versioning 2.0.0 rules and has a release lifecycle separate from the GraphDB
versions. The next table shows the version compatability between GraphDB, and the Terraform module.

| GraphDB Terraform                                                              | GraphDB                                                                               |
|--------------------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| [Version 1.x.x](https://github.com/Ontotext-AD/terraform-aws-graphdb/releases) | [Version 10.6.x](https://graphdb.ontotext.com/documentation/10.6/release-notes.html)  |
| [Version 1.2.x](https://github.com/Ontotext-AD/terraform-aws-graphdb/releases) | [Version 10.7.x](https://graphdb.ontotext.com/documentation/10.7/release-notes.html)  |
| [Version 1.3.x](https://github.com/Ontotext-AD/terraform-aws-graphdb/releases) | [Version 10.8.x](https://graphdb.ontotext.com/documentation/10.8/release-notes.html)  |
| [Version 2.x.x](https://github.com/Ontotext-AD/terraform-aws-graphdb/releases) | [Version 11.x.x](https://graphdb.ontotext.com/documentation/11.0/release-notes.html)  |

You can track the particular version updates of GraphDB in the [changelog](CHANGELOG.md).

## Prerequisites

Before you begin using this Terraform module, ensure you meet the following prerequisites:

- **AWS CLI Installed**:
  [https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

- **Terraform Installed**: You should have Terraform installed on your local machine. You can download Terraform from
  the [https://developer.hashicorp.com/terraform/install?product_intent=terraform](https://developer.hashicorp.com/terraform/install?product_intent=terraform).

- **AWS Credentials**: Ensure that you have AWS credentials configured on your machine. You can configure AWS access
  keys and secret keys using the [AWS CLI](https://aws.amazon.com/cli/).

- **Terraform AWS Provider Configuration**: Configure the AWS provider in your Terraform project. You can add your AWS
  access and secret keys as environment variables or use other methods for provider configuration.

- **Terraform Configuration File**: Create a new Terraform configuration file in your project, and use this module by
  specifying its source.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| deployment\_restriction\_tag | Deployment tag used to restrict access via IAM policies | `string` | `"deploymentTag"` | no |
| common\_tags | (Optional) Map of common tags for all taggable AWS resources. | `map(string)` | `{}` | no |
| resource\_name\_prefix | Resource name prefix used for tagging and naming AWS resources | `string` | n/a | yes |
| aws\_region | AWS region to deploy resources into | `string` | n/a | yes |
| override\_owner\_id | Override the default owner ID used for the AMI images | `string` | `null` | no |
| assume\_role\_arn | IAM Role that should be used to access another account | `string` | `null` | no |
| assume\_role\_session\_name | (Optional) name of the session to be assumed to run session | `string` | `null` | no |
| assume\_role\_external\_id | The external ID can be any identifier that is known only by you and the third party. For example, you can use an invoice ID between you and the third party | `string` | `null` | no |
| assume\_role\_principal\_arn | (Optional) Principal for the IAM role assume policies | `string` | `null` | no |
| graphdb\_additional\_policy\_arns | List of additional IAM policy ARNs to attach to the instance IAM role | `list(string)` | `[]` | no |
| deploy\_backup | Deploy backup module | `bool` | `true` | no |
| backup\_schedule | Cron expression for the backup job. | `string` | `"0 0 * * *"` | no |
| backup\_retention\_count | Number of backups to keep. | `number` | `7` | no |
| backup\_enable\_bucket\_replication | Enable or disable S3 bucket replication | `bool` | `false` | no |
| lb\_internal | Whether the load balancer will be internal or public | `bool` | `false` | no |
| lb\_type | Type of load balancer to create. Supported: 'network' or 'application' | `string` | `"network"` | no |
| lb\_deregistration\_delay | Amount time, in seconds, for GraphDB LB target group to wait before changing the state of a deregistering target from draining to unused. | `string` | `300` | no |
| lb\_health\_check\_path | The endpoint to check for GraphDB's health status. | `string` | `"/rest/cluster/node/status"` | no |
| lb\_health\_check\_interval | (Optional) Interval in seconds for checking the target group healthcheck. Defaults to 10. | `number` | `10` | no |
| lb\_tls\_certificate\_arn | ARN of the TLS certificate, imported in ACM, which will be used for the TLS listener on the load balancer. | `string` | `""` | no |
| lb\_idle\_timeout | (Optional) The time in seconds that the connection is allowed to be idle. | `number` | `4000` | no |
| lb\_client\_keep\_alive\_timeout | (Optional) The time in seconds that the client connection is allowed to be idle. | `number` | `604800` | no |
| alb\_enable\_http2 | Enable HTTP/2 on the load balancer. | `bool` | `true` | no |
| lb\_tls\_policy | TLS security policy on the listener. | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |
| allowed\_inbound\_cidrs\_lb | (Optional) List of CIDR blocks to permit inbound traffic from to load balancer | `list(string)` | `null` | no |
| allowed\_inbound\_cidrs\_ssh | (Optional) List of CIDR blocks to permit for SSH to GraphDB nodes | `list(string)` | `null` | no |
| ec2\_instance\_type | EC2 instance type | `string` | `"r6i.2xlarge"` | no |
| ec2\_key\_name | (Optional) key pair to use for SSH access to instance | `string` | `null` | no |
| graphdb\_node\_count | Number of GraphDB nodes to deploy in ASG | `number` | `3` | no |
| vpc\_dns\_hostnames | Enable or disable DNS hostnames support for the VPC | `bool` | `true` | no |
| vpc\_id | Specify the VPC ID if you want to use existing VPC. If left empty it will create a new VPC | `string` | `""` | no |
| vpc\_public\_subnet\_ids | Define the Subnet IDs for the public subnets that are deployed within the specified VPC in the vpc\_id variable | `list(string)` | `[]` | no |
| vpc\_private\_subnet\_ids | Define the Subnet IDs for the private subnets that are deployed within the specified VPC in the vpc\_id variable | `list(string)` | `[]` | no |
| vpc\_private\_subnet\_cidrs | CIDR blocks for private subnets | `list(string)` | ```[ "10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19" ]``` | no |
| vpc\_public\_subnet\_cidrs | CIDR blocks for public subnets | `list(string)` | ```[ "10.0.128.0/20", "10.0.144.0/20", "10.0.160.0/20" ]``` | no |
| vpc\_cidr\_block | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |
| vpc\_dns\_support | Enable or disable the support of the DNS service | `bool` | `true` | no |
| single\_nat\_gateway | Enable or disable the option to have single NAT Gateway. | `bool` | `false` | no |
| enable\_nat\_gateway | Enable or disable the creation of the NAT Gateway | `bool` | `true` | no |
| vpc\_endpoint\_service\_accept\_connection\_requests | (Required) Whether or not VPC endpoint connection requests to the service must be accepted by the service owner - true or false. | `bool` | `true` | no |
| vpc\_endpoint\_service\_allowed\_principals | (Optional) The ARNs of one or more principals allowed to discover the endpoint service. | `list(string)` | `null` | no |
| vpc\_enable\_flow\_logs | Enable or disable VPC Flow logs | `bool` | `false` | no |
| vpc\_flow\_logs\_lifecycle\_rule\_status | Define status of the S3 lifecycle rule. Possible options are enabled or disabled. | `string` | `"Disabled"` | no |
| vpc\_flow\_logs\_expiration\_days | Define the days after which the VPC flow logs should be deleted | `number` | `7` | no |
| lb\_enable\_private\_access | Enable or disable the private access via PrivateLink to the GraphDB Cluster | `bool` | `false` | no |
| ami\_id | (Optional) User-provided AMI ID to use with GraphDB instances. If you provide this value, please ensure it will work with the default userdata script (assumes latest version of Ubuntu LTS). Otherwise, please provide your own userdata script using the user\_supplied\_userdata\_path variable. | `string` | `null` | no |
| graphdb\_version | GraphDB version | `string` | `"11.0.1"` | no |
| device\_name | The device to which EBS volumes for the GraphDB data directory will be mapped. | `string` | `"/dev/sdf"` | no |
| ebs\_volume\_type | Type of the EBS volumes, used by the GraphDB nodes. | `string` | `"gp3"` | no |
| ebs\_volume\_size | The size of the EBS volumes, used by the GraphDB nodes. | `number` | `500` | no |
| ebs\_volume\_throughput | Throughput for the EBS volumes, used by the GraphDB nodes. | `number` | `250` | no |
| ebs\_volume\_iops | IOPS for the EBS volumes, used by the GraphDB nodes. | `number` | `8000` | no |
| ebs\_default\_kms\_key | KMS key used for ebs volume encryption. | `string` | `"alias/aws/ebs"` | no |
| prevent\_resource\_deletion | Defines if applicable resources should be protected from deletion or not | `bool` | `true` | no |
| graphdb\_license\_path | Local path to a file, containing a GraphDB Enterprise license. | `string` | `null` | no |
| graphdb\_admin\_password | Password for the 'admin' user in GraphDB. | `string` | `null` | no |
| graphdb\_cluster\_token | Cluster token used for authenticating the communication between the nodes. | `string` | `null` | no |
| route53\_zone\_dns\_name | DNS name for the private hosted zone in Route 53 | `string` | `"graphdb.cluster"` | no |
| route53\_existing\_zone\_id | Route53 existing DNS zone ID to add Route53 records in Route 53 | `string` | `""` | no |
| graphdb\_external\_dns | External domain name where GraphDB will be accessed | `string` | `""` | no |
| deploy\_monitoring | Enable or disable toggle for monitoring | `bool` | `false` | no |
| monitoring\_route53\_measure\_latency | Enable or disable route53 function to measure latency | `bool` | `false` | no |
| monitoring\_actions\_enabled | Enable or disable actions on alarms | `bool` | `false` | no |
| monitoring\_sns\_topic\_endpoint | Define an SNS endpoint which will be receiving the alerts via email | `string` | `null` | no |
| monitoring\_sns\_protocol | Define an SNS protocol that you will use to receive alerts. Possible options are: Email, Email-JSON, HTTP, HTTPS. | `string` | `"email"` | no |
| monitoring\_enable\_detailed\_instance\_monitoring | If true, the launched EC2 instance will have detailed monitoring enabled | `bool` | `false` | no |
| monitoring\_endpoint\_auto\_confirms | Enable or disable endpoint auto confirm subscription to the sns topic | `bool` | `false` | no |
| monitoring\_log\_group\_retention\_in\_days | Log group retention in days | `number` | `30` | no |
| monitoring\_route53\_health\_check\_aws\_region | Define the region in which you want the monitoring to be deployed. It is used to define where the Route53 Availability Check will be deployed, since if it is not specified it will deploy the check in us-east-1 and if you deploy in different region it will not find the dimensions. | `string` | `"us-east-1"` | no |
| monitoring\_route53\_availability\_http\_port | Define the HTTP port for the Route53 availability check | `number` | `80` | no |
| monitoring\_route53\_availability\_https\_port | Define the HTTPS port for the Route53 availability check | `number` | `443` | no |
| monitoring\_enable\_availability\_tests | Enable Route 53 availability tests and alarms | `bool` | `true` | no |
| graphdb\_properties\_path | Path to a local file containing GraphDB properties (graphdb.properties) that would be appended to the default in the VM. | `string` | `null` | no |
| graphdb\_java\_options | GraphDB options to pass to GraphDB with GRAPHDB\_JAVA\_OPTS environment variable. | `string` | `null` | no |
| deploy\_logging\_module | Enable or disable logging module | `bool` | `false` | no |
| logging\_enable\_bucket\_replication | Enable or disable S3 bucket replication | `bool` | `false` | no |
| s3\_enable\_access\_logs | Enable or disable access logs | `bool` | `false` | no |
| s3\_access\_logs\_lifecycle\_rule\_status | Define status of the S3 lifecycle rule. Possible options are enabled or disabled. | `string` | `"Disabled"` | no |
| s3\_access\_logs\_expiration\_days | Define the days after which the S3 access logs should be deleted. | `number` | `30` | no |
| s3\_expired\_object\_delete\_marker | Indicates whether Amazon S3 will remove a delete marker with no noncurrent versions. If set to true, the delete marker will be expired; if set to false the policy takes no action. | `bool` | `true` | no |
| s3\_mfa\_delete | Enable MFA delete for either Change the versioning state of your bucket or Permanently delete an object version. Default is false. This cannot be used to toggle this setting but is available to allow managed buckets to reflect the state in AWS | `string` | `"Disabled"` | no |
| s3\_versioning\_enabled | Enable versioning. Once you version-enable a bucket, it can never return to an unversioned state. You can, however, suspend versioning on that bucket. | `string` | `"Enabled"` | no |
| s3\_abort\_multipart\_upload | Specifies the number of days after initiating a multipart upload when the multipart upload must be completed. | `number` | `7` | no |
| s3\_enable\_replication\_rule | Enable or disable S3 bucket replication | `string` | `"Disabled"` | no |
| existing\_lb\_arn | (Optional) ARN of an existing Load Balancer. If provided, the module will not create a new LB. | `string` | `""` | no |
| existing\_lb\_dns\_name | (Optional) Use the DNS Name of an existing Load Balancer. | `string` | `""` | no |
| existing\_lb\_subnets | (Optional) Provide the subnet/s of the existing Load Balancer | `list(string)` | `[]` | no |
| existing\_lb\_target\_group\_arns | (Optional) Provide existing LB target group ARNs to attach to the Load Balancer | `list(string)` | `[]` | no |
| lb\_access\_logs\_lifecycle\_rule\_status | Define status of the S3 lifecycle rule. Possible options are enabled or disabled. | `string` | `"Disabled"` | no |
| lb\_enable\_access\_logs | Enable or disable access logs for the NLB | `bool` | `false` | no |
| lb\_access\_logs\_expiration\_days | Define the days after which the LB access logs should be deleted. | `number` | `14` | no |
| bucket\_replication\_destination\_region | Define in which Region should the bucket be replicated | `string` | `null` | no |
| graphdb\_enable\_userdata\_scripts\_on\_reboot | (Experimental) Modifies cloud-config to always run user data scripts on EC2 boot | `bool` | `false` | no |
| graphdb\_user\_supplied\_scripts | A list of paths to user-supplied shell scripts (local files) to be injected as additional parts in the EC2 user\_data. | `list(string)` | `[]` | no |
| graphdb\_user\_supplied\_rendered\_templates | A list of strings containing pre-rendered shell script content to be added as parts in EC2 user\_data. | `list(string)` | `[]` | no |
| graphdb\_user\_supplied\_templates | A list of maps where each map contains a 'path' to the template file and a 'variables' map used to render it. | ```list(object({ path = string variables = map(any) }))``` | `[]` | no |
| create\_s3\_kms\_key | Enable creation of KMS key for S3 bucket encryption | `bool` | `false` | no |
| s3\_kms\_key\_admin\_arn | ARN of the role or user granted administrative access to the S3 KMS key. | `string` | `""` | no |
| s3\_key\_rotation\_enabled | Specifies whether key rotation is enabled. | `bool` | `true` | no |
| s3\_kms\_default\_key | Define default S3 KMS key | `string` | `"alias/aws/s3"` | no |
| s3\_cmk\_alias | The alias for the CMK key. | `string` | `"alias/graphdb-s3-cmk-key"` | no |
| s3\_kms\_key\_enabled | Specifies whether the key is enabled. | `bool` | `true` | no |
| s3\_key\_specification | Specification of the Key. | `string` | `"SYMMETRIC_DEFAULT"` | no |
| s3\_key\_deletion\_window\_in\_days | The waiting period, specified in number of days for AWS to delete the KMS key(Between 7 and 30). | `number` | `30` | no |
| s3\_cmk\_description | Description for the KMS Key | `string` | `"KMS key for S3 bucket encryption."` | no |
| s3\_external\_kms\_key\_arn | Externally provided KMS CMK | `string` | `""` | no |
| parameter\_store\_cmk\_alias | The alias for the CMK key. | `string` | `"alias/graphdb-param-cmk-key"` | no |
| parameter\_store\_key\_admin\_arn | ARN of the key administrator role for Parameter Store | `string` | `""` | no |
| parameter\_store\_key\_tags | A map of tags to assign to the resources. | `map(string)` | `{}` | no |
| parameter\_store\_key\_rotation\_enabled | Specifies whether key rotation is enabled. | `bool` | `true` | no |
| parameter\_store\_default\_key | Define default key for parameter store if no KMS key is used | `string` | `"alias/aws/ssm"` | no |
| parameter\_store\_key\_enabled | Specifies whether the key is enabled. | `bool` | `true` | no |
| parameter\_store\_key\_spec | Specification of the Key. | `string` | `"SYMMETRIC_DEFAULT"` | no |
| parameter\_store\_key\_deletion\_window\_in\_days | The waiting period, specified in number of days for AWS to delete the KMS key(Between 7 and 30). | `number` | `30` | no |
| parameter\_store\_cmk\_description | Description for the KMS Key | `string` | `"KMS key for Parameter Store bucket encryption."` | no |
| create\_parameter\_store\_kms\_key | Enable creation of KMS key for Parameter Store encryption | `bool` | `false` | no |
| parameter\_store\_external\_kms\_key | Externally provided KMS CMK | `string` | `""` | no |
| ebs\_key\_admin\_arn | ARN of the key administrator role for Parameter Store | `string` | `""` | no |
| ebs\_key\_tags | A map of tags to assign to the resources. | `map(string)` | `{}` | no |
| ebs\_key\_rotation\_enabled | Specifies whether key rotation is enabled. | `bool` | `true` | no |
| default\_ebs\_cmk\_alias | The alias for the default Managed key. | `string` | `"alias/aws/ebs"` | no |
| ebs\_cmk\_alias | Define custom alias for the CMK Key | `string` | `"alias/graphdb-cmk-ebs-key"` | no |
| ebs\_key\_spec | Specification of the Key. | `string` | `"SYMMETRIC_DEFAULT"` | no |
| ebs\_key\_deletion\_window\_in\_days | The waiting period, specified in number of days for AWS to delete the KMS key(Between 7 and 30). | `number` | `30` | no |
| ebs\_cmk\_description | Description for the KMS Key | `string` | `"KMS key for S3 bucket encryption."` | no |
| ebs\_external\_kms\_key | Externally provided KMS CMK | `string` | `""` | no |
| ebs\_key\_enabled | Enable or disable toggle for ebs volume encryption. | `bool` | `true` | no |
| create\_ebs\_kms\_key | Creates KMS key for the EBS volumes | `bool` | `false` | no |
| create\_sns\_kms\_key | Enable Customer managed keys for encryption. If set to false it will use AWS managed key. | `bool` | `false` | no |
| sns\_cmk\_description | Description for the KMS key for the encryption of SNS | `string` | `"KMS CMK Key to encrypt SNS topics"` | no |
| sns\_key\_admin\_arn | ARN of the role or user granted administrative access to the SNS KMS key. | `string` | `""` | no |
| deletion\_window\_in\_days | The waiting period, specified in number of days for AWS to delete the KMS key(Between 7 and 30). | `number` | `30` | no |
| sns\_external\_kms\_key | ARN of the external KMS key that will be used for encryption of SNS topics | `string` | `""` | no |
| sns\_cmk\_key\_alias | The alias for the SNS CMK key. | `string` | `"alias/graphdb-sns-cmk-key-alias"` | no |
| sns\_default\_kms\_key | ARN of the default KMS key that will be used for encryption of SNS topics | `string` | `"alias/aws/sns"` | no |
| sns\_key\_spec | Specification of the Key. | `string` | `"SYMMETRIC_DEFAULT"` | no |
| sns\_key\_enabled | Specifies whether the key is enabled. | `bool` | `true` | no |
| sns\_rotation\_enabled | Specifies whether key rotation is enabled. | `bool` | `true` | no |
<!-- END_TF_DOCS -->

## Usage

***Important Variables (Inputs)***

The following are the important variables you should configure when using this module:

- `aws_region`: The region in which GraphDB will be deployed.
- `ec2_instance_type`: The instance type for the GDB cluster nodes. This should match your performance and cost
  requirements.
- `graphdb_node_count`: The number of instances in the cluster. Recommended is 3, 5 or 7 to have consensus according to
  the [Raft algorithm](https://raft.github.io/). For a single node deployment set the value to 1.
- `graphdb_license_path` : The path where the license for the GraphDB resides.
- `graphdb_admin_password`: This variable allows you to set password of your choice. If nothing is specified it will be
  autogenerated, you can find the autogenerated password in the SSM Parameter Store. You should know that is
  base64 Encoded.

To use this module, follow these steps:

1. Copy and paste into your Terraform configuration, insert the variables, and run ``terraform init``:

    ```hcl
    module "graphdb" {
      source  = "Ontotext-AD/graphdb/aws"
      version = "~> 1.0"

      resource_name_prefix     = "graphdb"
      aws_region               = "us-east-1"
      ec2_instance_type        = "m5.xlarge"
      graphdb_license_path     = "path-to-graphdb-license"
      allowed_inbound_cidrs_lb = ["0.0.0.0/0"]
    }
    ```

2. Initialize the module and its required providers with:

    ```bash
    terraform init
    ```

3. Before deploying, make sure to inspect the plan output with:

    ```bash
    terraform plan
    ```

4. After a careful review of the output plan, deploy with:

    ```bash
    terraform apply
    ```

Once deployed, you should be able to access the environment at the generated FQDN that has been outputted at the end.

## Examples

In this section you will find examples regarding customizing your GraphDB deployment.

**GraphDB Configurations**

There are several ways to customize the GraphDB properties.

1. Using a Custom GraphDB Properties File:

    You can specify a custom GraphDB properties file using the `graphdb_properties_path` variable. For example:

    ```hcl
    graphdb_properties_path = "<path_to_custom_graphdb_properties_file>"
    ```

2. Setting Java Options with `graphdb_java_options`:

    Another option is to set Java options using the `graphdb_java_options` variable.
    For instance, if you want to print the command line flags, use:

    ```hcl
    graphdb_java_options = "-XX:+PrintCommandLineFlags"
    ```

Note: The options mention above will be appended to the ones set in the user data script.

**Customize GraphDB Version**

```hcl
graphdb_version = "11.0.1"
```

**Purge Protection**

Resources that support purge protection have them enabled by default. You can override the default configurations with
the following variables:

```hcl
prevent_resource_deletion = false
```

**Backup**

To enable deployment of the backup module, you need to enable the following flag:

```hcl
deploy_backup = true
```

**Monitoring**

To enable deployment of the monitoring module, you need to enable the following flag:

```hcl
deploy_monitoring = true
```

**Providing a TLS certificate**

```hcl
# Example ARN
lb_tls_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
```

**Private Deployment**

To ensure access to GraphDB exclusively through a private network, you must set the following variables to `true`:

```hcl
# Enable creation of a private service endpoint
lb_enable_private_access = true
# Enable private access to the Network Load Balancer and disable public access
lb_internal = true
```

By configuring these variables accordingly you enforce GraphDB accessibility solely via a private network, enhancing security and control over network traffic.

**Logging**

To enable the logging feature the first thing that you should do is to switch the `deploy_logging_module` variable to `true`.

There are several logging features that can be enabled with the following variables:

**EBS Volume Configurations**

This Terraform module creates EBS volumes and mounts them to EC2 instances to store data.
You can modify the default settings by changing the values of the following variables:

```hcl
ebs_volume_size                            = 1024
ebs_volume_iops                            = 10000
ebs_volume_throughput                      = 500
```

#### S3 Access Logs

To enable the S3 Bucket access logs for the backup bucket you should switch the following values to `true`:

```hcl
deploy_logging_module = true
s3_access_logs_lifecycle_rule_status = "Enabled"
s3_enable_access_logs = true
```

#### Load Balancer Access Logs

To enable the load balancer logs you should enable the following variables to `true`:

```hcl
deploy_logging_module = true
lb_access_logs_lifecycle_rule_status = true
lb_enable_access_logs = true
```

#### VPC Flow Logs

To enable the VPC Flow logs you should switch the following variables to `true`:

```hcl
deploy_logging_module = true
vpc_enable_flow_logs = true
vpc_flow_logs_lifecycle_rule_status = "Enabled"
```

#### KMS Encryption using Customer Master Keys

**Parameter Store encryption**

You can encrypt parameters stored in AWS Systems Manager Parameter Store using KMS CMKs. This ensures that sensitive data,
such as configuration secrets, are securely encrypted at rest.

##### Keys

To utilize CMK, you should set the following variable  `enable_graphdb_parameter_store_kms_key` to `true`.
This will generate a new KMS Key.

If `enable_graphdb_parameter_store_kms_key` is set to `false`, the encryption will be disabled.

You can also provide your own key using the `parameter_store_external_kms_key` variable.

```hcl
enable_graphdb_parameter_store_kms_key = true
parameter_store_external_kms_key       = "arn:aws:kms:us-east-1:123456789012:key/your-external-key-arn"
```

##### Key Admin

You can designate a Key admin by setting the `graphdb_parameter_store_key_admin_arn` variable,
or you can use the current AWS account by leaving this parameter empty.

```hcl
graphdb_parameter_store_key_admin_arn = "arn:aws:iam::123456789012:role/KeyAdminRole"
```

##### Using Custom Principal ARN

You can set custom principal for the EBS Key Admin Role and for the Parameter Store Admin Role via the following variable:

```hcl
assume_role_principal_arn = "arn:aws:iam::${accountID}:role/$USER or $ROLE"
```

**EBS encryption**

You can enhance the security of EBS volumes by using KMS CMKs to encrypt data at rest.
This provides an additional layer of protection for data stored on EBS volumes attached to EC2 instances.

##### Keys

To enable CMK, set `create_graphdb_ebs_kms_key` to `true`. This will create a new KMS Key.

If `create_graphdb_ebs_kms_key` is set to `false` the default AWS key encryption will be used.

You can also provide your own key using the `ebs_external_kms_key` variable.

```hcl
create_graphdb_ebs_kms_key = true
ebs_external_kms_key = "arn:aws:kms:us-east-1:123456789012:key/your-external-key-arn"
```

##### Key Admin

You can designate a Key admin by setting the `graphdb_ebs_key_admin_arn` variable,
or you can use the current AWS account by leaving this parameter empty.

```hcl
graphdb_ebs_key_admin_arn = "arn:aws:iam::123456789012:role/KeyAdminRole"
```

**S3 encryption**

You can secure S3 bucket objects by encrypting them with KMS CMKs, ensuring data at rest is protected.
This safeguards the integrity and confidentiality of data stored in S3 buckets.

##### Keys

To use CMK, set `create_s3_kms_key` to `true`. This will create a new KMS Key.

If `create_s3_kms_key` is set to `false`, the default AWS key `alias/aws/s3` will be used.

You can also provide your own key using the `s3_external_kms_key_arn` variable.

```hcl
create_s3_kms_key = true
s3_external_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/your-external-key-arn"
```

##### Key Admin

You can designate a Key admin by setting the `s3_kms_key_admin_arn` variable,
or you can use the current AWS account by leaving this parameter empty.

```hcl
s3_kms_key_admin_arn = "arn:aws:iam::123456789012:role/KeyAdminRole"
```

#### Replication

You can enable replication for S3 buckets by setting the following variables to true:

```hcl
logging_enable_bucket_replication = true
s3_enable_replication_rule = "Enabled"
```

#### Deploying in an existing VPC

If you have an existing VPC in your account, you can use it to deploy the GraphDB cluster.

Just specify values for the following variables:

```hcl
vpc_id = "vpc-12345678"
vpc_public_subnet_ids = ["subnet-123456","subnet-234567","subnet-345678"]
vpc_private_subnet_ids = ["subnet-456789","subnet-567891","subnet-678912"]
```

### AWS Provider Assume Role Configuration

This module allows you to configure the AWS provider to assume a role in another account for cross-account management. You can configure the following variables to control the assume_role behavior:

```hcl
assume_role_arn           = "arn:aws:iam::accountID:role/rolename"
assume_role_external_id = "exampleId"
assume_role_session_name = "session"
```

### Deploying in an existing Route53 Private Hosted Zone

If you want to deploy the GraphDB cluster in an existing Route 53 Private Hosted Zone, follow the steps below to configure the necessary variables.

```hcl
route53_existing_zone_id = "ZONE_ID"
vpc_id = "vpc-12345678"
vpc_public_subnet_ids = ["subnet-123456","subnet-234567","subnet-345678"]
vpc_private_subnet_ids = ["subnet-456789","subnet-567891","subnet-678912"]
```

#### User Data Customization

- Providing user_supplied_scripts

Paths to local shell script files that will be injected into the instance user data.
Each file should be a valid shell script.
•	Scripts are executed in the order provided.

```hcl
user_supplied_scripts = [
"${path.module}/scripts/init.sh",
"${path.module}/scripts/configure.sh"
]
```
- Providing user_supplied_rendered_templates

A list of raw shell script strings, already rendered, which will be included directly into the instance user data.

```hcl
user_supplied_rendered_templates = [
  <<-EOT
    #!/bin/bash
    echo "Inline startup task"
    export ENV=production
  EOT
]
```

- Providing user_supplied_templates

A list of template files (plus variables) that will be rendered and included into the instance user data.

```hcl
graphdb_user_supplied_templates = [
  {
    path = "/path/to/yourscript.sh.tpl"
    variables = {
      s3_bucket_url = "s3://bucket-name"
    }
  }
]
```

#### Attaching additional IAM policies

- To grant extra permissions to the instance role used by the GraphDB module, you can attach additional IAM policies
  by specifying their ARNs in the graphdb_additional_policy_arns variable. This variable accepts a list of policy ARNs.
  For example, if you want to attach two additional policies, you can configure the variable as follows:

```hcl
graphdb_additional_policy_arns = [
  "arn:aws:iam::123456789012:policy/ExtraPolicy1",
  "arn:aws:iam::123456789012:policy/ExtraPolicy2"
]
```

#### Using Existing Load Balancer

To deploy the GraphDB module with an existing Load Balancer, configure the module with the ARN, DNS name,
subnets, and target group ARNs of a pre-existing NLB, along with the VPC and subnet IDs.

 PREREQUISITES:

 * Create your VPC (with the public & private subnets).
 * Provision a  Load Balancer in those public subnets.
 * Create a Target Group (initially empty) whose:
   * Protocol = TCP
   * Port     = 7201 for single-node, or 7200 for multi-node clusters
   * Health-check protocol = TCP, same port as above


Configure the module by specifying the following variables:

```hcl
existing_lb_arn               = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/net/<YOUR-LB-NAME>/<LB-ID>"
existing_lb_dns_name          = "<YOUR-LB-NAME>-<LB-ID>.elb.us-east-1.amazonaws.com"
existing_lb_subnets           = ["subnet-aaaaaaaaaaaaaaaaa", "subnet-bbbbbbbbbbbbbbbbb", "subnet-ccccccccccccccccc"]
existing_lb_target_group_arns = ["arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/<YOUR-TG-NAME>/<TG-ID>"]
vpc_id                        = "vpc-0123456789abcdef0"
vpc_private_subnet_ids        = ["subnet-ddddddddddddddddd", "subnet-eeeeeeeeeeeeeeeee", "subnet-fffffffffffffffff"]
vpc_public_subnet_ids         = ["subnet-ggggggggggggggggg", "subnet-hhhhhhhhhhhhhhhhh", "subnet-iiiiiiiiiiiiiiiii"]
```

#### Selecting Load Balancer Type

By default, this module deploys a Network Load Balancer (NLB), which operates at Layer 4 and supports configuration of the TCP keep-alive timeout. This is useful for supporting long-running requests (e.g., SPARQL queries).

However, NLBs do not support HTTP routing (such as host-based rules). If that's the case, we recommend using an Application Load Balancer (ALB) instead.

To switch to ALB, set the following variable:

```hcl
lb_type = "application"
```

💡 Note: ALBs support idle timeouts of up to [7 days](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/edit-load-balancer-attributes.html#http-client-keep-alive-duration), which is ideal for persistent connections and long-running operations over HTTP/HTTPS.

## Single Node Deployment

This Terraform module can deploy a single instance of GraphDB.
To do this, set `graphdb_node_count` to `1`, and the rest will be handled automatically.

**Important:** Scaling from a single-node deployment to a cluster deployment (e.g., changing `graphdb_node_count` from 1 to 3)
is not fully automated. While the Terraform module will allow you to scale up and create 3 instances,
the cluster will not be formed unless you terminate the initial node.

**Note:** Make sure that the new instances are running before terminating the initial node.

**Please note that this operation is disruptive, and there is a risk that things may not go as expected.**

**Note:** Scaling down a cluster to a single node is not supported. To do this you need to:
1. Disable user access
2. Deleted the cluster
3. Manually scale down to `0`
4. Apply the module with `graphdb_node_count = 1`

Also, the EBS for the deleted instances need to be removed

## Updating configurations on an active deployment

### Updating Configurations

When faced with scenarios such as an expired license, or the need to modify the `graphdb.properties` file or other
GraphDB-related configurations, you can apply changes via `terraform apply` and then you can either:

- Manually terminate instances one by one, beginning with the follower nodes and concluding with the leader node
as the last instance to be terminated.
- Scale in the number of instances in the scale set to zero and then scale back up to the original number of nodes.
- Set the graphdb_enable_userdata_scripts_on_reboot variable to true. This ensures that user data scripts are executed
on each reboot, allowing you to update the configuration of each node.
The reboot option would essentially achieve the same outcome as the termination and replacement approach, but it is still experimental.

```text
Please note that the scale in and up option will result in greater downtime than the other options, where the downtime should be less.
```

Both actions will trigger the user data script to run again, updating files and properties overrides with the new values.
Please note that changing the `graphdb_admin_password` via `terraform apply` will not update the password in GraphDB.
Support for this will be introduced in the future.

### Upgrading GraphDB Version

Updating the graphdb version is performed by changing the value of `graphdb_version` property and executing `terraform apply`.

Note that the EC2 instances won't be automatically updated to the latest model, and they need to be recreated.
Make sure the instances are recreated one by one, allowing them time to rejoin the cluster, to avoid downtime and
unexpected behavior.

## Local Development

Instead of using the module dependency, you can create a local variables file named `terraform.tfvars` and provide
configuration overrides there.
Here's an example of a `terraform.tfvars` file:

### terraform.tfvars

```hcl

aws_region = "us-east-1"

resource_name_prefix = "my-prefix"

graphdb_license_path = "/path/to/your/license.license"

ec2_instance_type = "c5a.2xlarge"

allowed_inbound_cidrs_lb = ["0.0.0.0/0"]
```

## Release History

All notable changes between version are tracked and documented at [CHANGELOG.md](CHANGELOG.md).

## Contributing

Check out the contributors guide [CONTRIBUTING.md](CONTRIBUTING.md).

## License

This code is released under the Apache 2.0 License. See [LICENSE](LICENSE) for more details.
