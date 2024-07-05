resource "random_password" "graphdb_admin_password" {
  count   = var.graphdb_admin_password != null ? 0 : 1
  length  = 8
  special = true
}

resource "random_password" "graphdb_cluster_token" {
  count   = var.graphdb_cluster_token != null ? 0 : 1
  length  = 16
  special = true
}

locals {
  graphdb_cluster_token  = var.graphdb_cluster_token != null ? var.graphdb_cluster_token : random_password.graphdb_cluster_token[0].result
  graphdb_admin_password = var.graphdb_admin_password != null ? var.graphdb_admin_password : random_password.graphdb_admin_password[0].result
}

resource "aws_ssm_parameter" "graphdb_admin_password" {
  name        = "/${var.resource_name_prefix}/graphdb/admin_password"
  description = "Password for the 'admin' user in GraphDB."
  type        = "SecureString"
  value       = base64encode(local.graphdb_admin_password)
  key_id      = var.parameter_store_key_arn
}

resource "aws_ssm_parameter" "graphdb_cluster_token" {
  name        = "/${var.resource_name_prefix}/graphdb/cluster_token"
  description = "Cluster token used for authenticating the communication between the nodes."
  type        = "SecureString"
  value       = base64encode(local.graphdb_cluster_token)
  key_id      = var.parameter_store_key_arn
}

resource "aws_ssm_parameter" "graphdb_license" {
  name        = "/${var.resource_name_prefix}/graphdb/license"
  description = "GraphDB Enterprise license."
  type        = "SecureString"
  value       = filebase64(var.graphdb_license_path)
  key_id      = var.parameter_store_key_arn
}

resource "aws_ssm_parameter" "graphdb_lb_dns_name" {
  name        = "/${var.resource_name_prefix}/graphdb/lb_dns_name"
  description = "The DNS name of the load balancer for the GraphDB nodes."
  type        = "String"
  value       = var.graphdb_lb_dns_name
}

resource "aws_ssm_parameter" "graphdb_properties" {
  count = var.graphdb_properties_path != null ? 1 : 0

  name        = "/${var.resource_name_prefix}/graphdb/graphdb_properties"
  description = "Additional properties to append to graphdb.properties file."
  type        = "SecureString"
  value       = filebase64(var.graphdb_properties_path)
  key_id      = var.parameter_store_key_arn
}

resource "aws_ssm_parameter" "graphdb_java_options" {
  count = var.graphdb_java_options != null ? 1 : 0

  name        = "/${var.resource_name_prefix}/graphdb/graphdb_java_options"
  description = "GraphDB options to pass to GraphDB with GRAPHDB_JAVA_OPTS environment variable."
  type        = "SecureString"
  value       = var.graphdb_java_options
  key_id      = var.parameter_store_key_arn
}
