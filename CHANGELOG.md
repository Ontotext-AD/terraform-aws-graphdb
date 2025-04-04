# GraphDB AWS Terraform Module Changelog

## 1.5.0
* Added ability to provide additional ARNs for IAM Policies
* Added ability to get dynamic http protocol for gdb_conf_overrides based on the lb_certificate_arn
* Removed the `asg_enable_instance_refresh` property and the instance auto-refresh functionality.
* Fixed issue where the cluster was not formed when scaling from 1 node to 3 or more nodes.
* Updated backup script to use the new multipart endpoint

## 1.4.1

* Update default GraphDB version to [10.8.5](https://graphdb.ontotext.com/documentation/10.8/release-notes.html#graphdb-10-8-5)

## 1.4.0

* Added ability to specify IAM role to be assumed in provider.tf
* Added ability to use existing Route53 Private hosted zone
* Updated Provider version in versions.tf
* Removed the provisioning of Route53 Hosted zone when deploying a single node.
* Added ability to use custom principal for EBS Admin Role and Param Store Admin role via assume_role_principal_arn variable
* Updated graphdb_instance_ssm policy in iam.tf - added restrictions on ssm:DescribeParameters to only allow usage on graphdb-related resources.
* Updated graphdb_instance_ssm policy in iam.tf - restricted kms actions to Decrypt only
* Changed owner of /etc/prometheus to cwagent:cwagent. Removed rw permissions for /etc/prometheus/prometheus.yaml for other an group users
* Removed access to aws cli for users other than root
* Added a toggle for enabling/disabling the availability tests in CloudWatch
* Added new variable, deployment_restriction_tag to be used for tagging resources as part of the deployment. This allows for stricter IAM policies on certain (dangerous) actions
* Changed graphdb_instance_volume policy to restrict ec2:AttachVolume and ec2:CreateVolume for only specifically tagged volumes
* Extended graphdb_instance_volume_tagging by adding an additional constraint on ec2:CreateTags to allow instances that are already tagged with deployment_restriction_tag to be tagged with a Name
* Added ability to attach custom user data scripts, templates or rendered templates to the EC2 Userdata

## 1.3.4

* Update default GraphDB version to [10.8.4](https://graphdb.ontotext.com/documentation/10.8/release-notes.html#graphdb-10-8-4)

## 1.3.3

* Update default GraphDB version to [10.8.3](https://graphdb.ontotext.com/documentation/10.8/release-notes.html#graphdb-10-8-3)

## 1.3.2

* Update default GraphDB version to [10.8.2](https://graphdb.ontotext.com/documentation/10.8/release-notes.html#graphdb-10-8-2)

## 1.3.1

* Update default GraphDB version to [10.8.1](https://graphdb.ontotext.com/documentation/10.8/release-notes.html#graphdb-10-8-1)

## 1.3.0

* Update default GraphDB version to [10.8.0](https://graphdb.ontotext.com/documentation/10.8/release-notes.html#graphdb-10-8-0)

## 1.2.8

* Update default GraphDB Version to [10.7.6](https://graphdb.ontotext.com/documentation/10.7/release-notes.html#graphdb-10-7-6)

## 1.2.7
* Update default GraphDB Version to [10.7.5](https://graphdb.ontotext.com/documentation/10.7/release-notes.html#graphdb-10-7-5)

## 1.2.6

* Fixed issue with wrong protocol leading to nodes miscommunication
* Update default GraphDB version to [10.7.4](https://graphdb.ontotext.com/documentation/10.7/release-notes.html#graphdb-10-7-4)

## 1.2.5

* Update default GraphDB version to [10.7.3](https://graphdb.ontotext.com/documentation/10.7/release-notes.html#graphdb-10-7-3)

## 1.2.4

* Update default GraphDB version to [10.7.2](https://graphdb.ontotext.com/documentation/10.7/release-notes.html#graphdb-10-7-2)

## 1.2.3

* Removed unused resource "aws_ssm_parameter" named "graphdb_lb_dns_name"
* Fixed `graphdb.properties` values for single node deployment:
  * Changed `graphdb.external-url` to use `LB_DNS_RECORD` when single node is deployed.
  * Added `graphdb.external-url.enforce.transactions=true`
* Removed calculation of `lb_tls_enabled` in the LB module as it is calculated in the main.tf
* Removed `monitoring_route53_healtcheck_fqdn_url` in favor of `graphdb_external_dns`.
* Change default EC2 instance type r6i.2xlarge
* Update default GraphDB version to [10.7.1](https://graphdb.ontotext.com/documentation/10.7/release-notes.html#graphdb-10-7-1)

## 1.2.2

* Fixed issues with variables in the backup user data script
* Added ability to choose http port for Route53 availability check
* Added ability to specify custom FQDN for the Route53 availability URL

## 1.2.1

* Fixed issue where the backup script was not configured

## 1.2.0

* Added support for single node deployment
  * Added new userdata script `10_start_graphdb_services.sh.tpl` for single node setup.
  * Made cluster-related userdata scripts executable only when graphdb_node_count is greater than 1.
* Removed hardcoded values from the userdata scripts.
* Changed the availability tests http_string_type to be calculated based on TLS being enabled.
* Bumped GraphDB version to [10.7.0](https://graphdb.ontotext.com/documentation/10.7/release-notes.html#graphdb-10-7-0)

## 1.1.0

* Added support for CMK Keys
* Added support to use existing VPC and subnets to deploy the GraphDB cluster

## 1.0.1

* Updated GraphDB version to [10.6.4](https://graphdb.ontotext.com/documentation/10.6/release-notes.html#graphdb-10-6-4)

## 1.0.0
* Updated the user data scripts to allow setup of multi node cluster based on the `node_count` variable.
* Added ability for a node to rejoin the cluster if raft folder is empty or missing.
* Added stable network names based on AZ deployment.

## 0.1.0

* Initial version for GraphDB AWS module
