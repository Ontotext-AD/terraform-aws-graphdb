# GraphDB AWS Terraform Module Changelog

# 1.2.3

* Removed unused resource "aws_ssm_parameter" named "graphdb_lb_dns_name"
* Fixed `graphdb.properties` values for single node deployment:
  * Changed `graphdb.external-url` to use `LB_DNS_RECORD` when single node is deployed.
  * Added `graphdb.external-url.enforce.transactions=true`
* Removed calculation of `lb_tls_enabled` in the LB module as it is calculated in the main.tf
* Removed `monitoring_route53_healtcheck_fqdn_url` in favor of `graphdb_external_dns`.

# 1.2.2

* Fixed issues with variables in the backup user data script
* Added ability to choose http port for Route53 availability check
* Added ability to specify custom FQDN for the Route53 availability URL

# 1.2.1

* Fixed issue where the backup script was not configured

# 1.2.0

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
