# GraphDB AWS Terraform Module

This Terraform module allows you to provision an GraphDB cluster within a Virtual Private Cloud (VPC). The module
provides a flexible way to configure the cluster and the associated VPC components. It implements the GraphDB reference
architecture. Check the official [documentation](https://graphdb.ontotext.com/documentation/10.6/aws-deployment.html)
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

<p>
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
versions. The next table shows the version compatability between GraphDB and the Terraform module.

| GraphDB Terraform                                                              | GraphDB                                                                              |
|--------------------------------------------------------------------------------|--------------------------------------------------------------------------------------|
| [Version 0.0.1](https://github.com/Ontotext-AD/terraform-aws-graphdb/releases) | [Version 10.6.x](https://graphdb.ontotext.com/documentation/10.6/release-notes.html) |

You can track the particular version updates of GraphDB in the [changelog](CHANGELOG.md).

## Prerequisites

Before you begin using this Terraform module, ensure you meet the following prerequisites:

- **AWS CLI Installed
  **: [https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

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
| common\_tags | (Optional) Map of common tags for all taggable AWS resources. | `map(string)` | `{}` | no |
| resource\_name\_prefix | Resource name prefix used for tagging and naming AWS resources | `string` | n/a | yes |
| aws\_region | AWS region to deploy resources into | `string` | n/a | yes |
| deploy\_backup | Deploy backup module | `bool` | `true` | no |
| backup\_schedule | Cron expression for the backup job. | `string` | `"0 0 * * *"` | no |
| backup\_retention\_count | Number of backups to keep. | `number` | `7` | no |
| lb\_internal | Whether the load balancer will be internal or public | `bool` | `false` | no |
| lb\_deregistration\_delay | Amount time, in seconds, for GraphDB LB target group to wait before changing the state of a deregistering target from draining to unused. | `string` | `300` | no |
| lb\_health\_check\_path | The endpoint to check for GraphDB's health status. | `string` | `"/rest/cluster/node/status"` | no |
| lb\_health\_check\_interval | (Optional) Interval in seconds for checking the target group healthcheck. Defaults to 10. | `number` | `10` | no |
| lb\_tls\_certificate\_arn | ARN of the TLS certificate, imported in ACM, which will be used for the TLS listener on the load balancer. | `string` | `null` | no |
| lb\_tls\_policy | TLS security policy on the listener. | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |
| allowed\_inbound\_cidrs\_lb | (Optional) List of CIDR blocks to permit inbound traffic from to load balancer | `list(string)` | `null` | no |
| allowed\_inbound\_cidrs\_ssh | (Optional) List of CIDR blocks to permit for SSH to GraphDB nodes | `list(string)` | `null` | no |
| ec2\_instance\_type | EC2 instance type | `string` | `"r6g.2xlarge"` | no |
| ec2\_key\_name | (Optional) key pair to use for SSH access to instance | `string` | `null` | no |
| graphdb\_node\_count | Number of GraphDB nodes to deploy in ASG | `number` | `3` | no |
| vpc\_dns\_hostnames | Enable or disable DNS hostnames support for the VPC | `bool` | `true` | no |
| create\_vpc | Enable or disable the creation of the VPC | `bool` | `true` | no |
| vpc\_private\_subnet\_cidrs | CIDR blocks for private subnets | `list(string)` | ```[ "10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19" ]``` | no |
| vpc\_public\_subnet\_cidrs | CIDR blocks for public subnets | `list(string)` | ```[ "10.0.128.0/20", "10.0.144.0/20", "10.0.160.0/20" ]``` | no |
| vpc\_cidr\_block | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |
| vpc\_dns\_support | Enable or disable the support of the DNS service | `bool` | `true` | no |
| single\_nat\_gateway | Enable or disable the option to have single NAT Gateway. | `bool` | `false` | no |
| enable\_nat\_gateway | Enable or disable the creation of the NAT Gateway | `bool` | `true` | no |
| ami\_id | (Optional) User-provided AMI ID to use with GraphDB instances. If you provide this value, please ensure it will work with the default userdata script (assumes latest version of Ubuntu LTS). Otherwise, please provide your own userdata script using the user\_supplied\_userdata\_path variable. | `string` | `null` | no |
| graphdb\_version | GraphDB version | `string` | `"10.6.2"` | no |
| device\_name | The device to which EBS volumes for the GraphDB data directory will be mapped. | `string` | `"/dev/sdf"` | no |
| ebs\_volume\_type | Type of the EBS volumes, used by the GraphDB nodes. | `string` | `"gp3"` | no |
| ebs\_volume\_size | The size of the EBS volumes, used by the GraphDB nodes. | `number` | `500` | no |
| ebs\_volume\_throughput | Throughput for the EBS volumes, used by the GraphDB nodes. | `number` | `250` | no |
| ebs\_volume\_iops | IOPS for the EBS volumes, used by the GraphDB nodes. | `number` | `8000` | no |
| ebs\_kms\_key\_arn | KMS key used for ebs volume encryption. | `string` | `"alias/aws/ebs"` | no |
| prevent\_resource\_deletion | Defines if applicable resources should be protected from deletion or not | `bool` | `true` | no |
| graphdb\_license\_path | Local path to a file, containing a GraphDB Enterprise license. | `string` | `null` | no |
| graphdb\_admin\_password | Password for the 'admin' user in GraphDB. | `string` | `null` | no |
| graphdb\_cluster\_token | Cluster token used for authenticating the communication between the nodes. | `string` | `null` | no |
| route53\_zone\_dns\_name | DNS name for the private hosted zone in Route 53 | `string` | `"graphdb.cluster"` | no |
| deploy\_monitoring | Enable or disable toggle for monitoring | `bool` | `false` | no |
| monitoring\_route53\_measure\_latency | Enable or disable route53 function to measure latency | `bool` | `true` | no |
| monitoring\_actions\_enabled | Enable or disable actions on alarms | `bool` | `true` | no |
| monitoring\_sns\_topic\_endpoint | Define an SNS endpoint which will be receiving the alerts via email | `string` | `null` | no |
| monitoring\_sns\_protocol | Define an SNS protocol that you will use to receive alerts. Possible options are: Email, Email-JSON, HTTP, HTTPS. | `string` | `"email"` | no |
| monitoring\_endpoint\_auto\_confirms | Enable or disable endpoint auto confirm subscription to the sns topic | `bool` | `false` | no |
| monitoring\_log\_group\_retention\_in\_days | Log group retention in days | `number` | `30` | no |
| monitoring\_route53\_health\_check\_aws\_region | Define the region in which you want the monitoring to be deployed. It is used to define where the Route53 Availability Check will be deployed, since if it is not specified it will deploy the check in us-east-1 and if you deploy in different region it will not find the dimensions. | `string` | `"us-east-1"` | no |
| graphdb\_properties\_path | Path to a local file containing GraphDB properties (graphdb.properties) that would be appended to the default in the VM. | `string` | `null` | no |
| graphdb\_java\_options | GraphDB options to pass to GraphDB with GRAPHDB\_JAVA\_OPTS environment variable. | `string` | `null` | no |
<!-- END_TF_DOCS -->

## Usage

***Important Variables (Inputs)***

The following are the important variables you should configure when using this module:

- `aws_region`: The region in which GraphDB will be deployed.
- `ec2_instance_type`: The instance type for the GDB cluster nodes. This should match your performance and cost
  requirements.
- `graphdb_node_count`: The number of instances in the cluster. Recommended is 3, 5 or 7 in order to have consensus according to
  the [Raft algorithm](https://raft.github.io/).
- `graphdb_license_path` : The path where the license for the GraphDB resides.
- `graphdb_admin_password`: This variable allows you to set password of your choice. If nothing is specified it will be
  autogenerated, you can find the autogenerated password in the SSM Parameter Store. You should know that is
  base64 Encoded.

To use this module, follow these steps:

Copy and paste into your Terraform configuration, insert the variables, and run ``terraform init``:

```hcl
module "graphdb" {
  source  = "Ontotext-AD/graphdb/aws"
  version = "0.0.1"

  resource_name_prefix     = "graphdb"
  aws_region               = "us-east-1"
  ec2_instance_type        = "c5a.2xlarge"
  graphdb_license_path     = "path-to-graphdb-license"
  allowed_inbound_cidrs_lb = ["0.0.0.0/0"]
}
```
Initialize the module and it's required providers with:

`terraform init`

Before deploying, make sure to inspect the plan output with:

`terraform plan`

After a careful review of the output plan, deploy with:

`terraform apply`

Once deployed, you should be able to access the environment at the generated FQDN that has been outputted at the end.

## Examples
In this section you will find examples regarding customizing your GraphDB Configuration.

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
graphdb_version = "10.6.3"
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

## Updating configurations on an active deployment

In case your license has expired, and you need to renew it, or you need to make some changes to the `graphdb.properties`
file, or other GraphDB related configurations, you will need to apply the changes via `terraform apply` and then either:

- Terminate the instances one by one, starting with the follower nodes, and leaving the leader node to be the last
  instance to be terminated
- Scale down to 0 and back to number of nodes you originally had.

```text
Please be aware that the latter option will result in some downtime.
```

Both actions would trigger the user data script to be run again and update all files and properties overrides with the
updated values.

## Local Development

Instead of using the module dependency, you can create a local variables file named `terraform.tfvars` and provide
configuration overrides there.
Here's an example of a terraform.tfvars file:

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
