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

  # The "graphdb_ssm_versions" map stores dynamically computed version numbers
  # for various SSM parameters based on their content. This version number changes
  # automatically when the content changes (forcing an update to the parameter).
  # The version is computed as follows:
  #   1. The content (secret string or file content) is encoded (using base64encode() for strings or filebase64() for files),
  #      ensuring the data is in a consistent format.
  #   2. The MD5 hash of the encoded value is calculated. This produces a 32-character hexadecimal string.
  #   3. The first 12 characters of the MD5 hash are extracted with substr(..., 0, 12). This substring acts as a fingerprint.
  #   4. parseint(..., 16) converts the hexadecimal substring to a decimal number.
  graphdb_ssm_versions = {
    admin_password = var.graphdb_admin_password != "" ? parseint(
      substr(md5(base64encode(local.graphdb_admin_password)), 0, 12),
      16
    ) : 1

    cluster_token = var.graphdb_cluster_token != "" ? parseint(
      substr(md5(base64encode(local.graphdb_cluster_token)), 0, 12),
      16
    ) : 1

    license = var.graphdb_license_path != "" ? parseint(
      substr(md5(filebase64(var.graphdb_license_path)), 0, 12),
      16
    ) : 1

    properties = (var.graphdb_properties_path != null && var.graphdb_properties_path != "") ? parseint(
      substr(md5(filebase64(var.graphdb_properties_path)), 0, 12),
      16
    ) : 1

    java_options = (var.graphdb_java_options != null && var.graphdb_java_options != "") ? parseint(
      substr(md5(var.graphdb_java_options), 0, 12),
      16
    ) : 1
  }
}

resource "aws_ssm_parameter" "graphdb_admin_password" {
  name             = "/${var.resource_name_prefix}/graphdb/admin_password"
  description      = "Password for the 'admin' user in GraphDB."
  type             = "SecureString"
  value_wo         = base64encode(local.graphdb_admin_password)
  value_wo_version = local.graphdb_ssm_versions.admin_password
  key_id           = var.parameter_store_key_arn
}

resource "aws_ssm_parameter" "graphdb_cluster_token" {
  name             = "/${var.resource_name_prefix}/graphdb/cluster_token"
  description      = "Cluster token used for authenticating the communication between the nodes."
  type             = "SecureString"
  value_wo         = base64encode(local.graphdb_cluster_token)
  value_wo_version = local.graphdb_ssm_versions.cluster_token
  key_id           = var.parameter_store_key_arn
}

resource "aws_ssm_parameter" "graphdb_license" {
  name             = "/${var.resource_name_prefix}/graphdb/license"
  description      = "GraphDB Enterprise license."
  type             = "SecureString"
  value_wo         = filebase64(var.graphdb_license_path)
  value_wo_version = local.graphdb_ssm_versions.license
  key_id           = var.parameter_store_key_arn
}

resource "aws_ssm_parameter" "graphdb_properties" {
  count = var.graphdb_properties_path != null ? 1 : 0

  name             = "/${var.resource_name_prefix}/graphdb/graphdb_properties"
  description      = "Additional properties to append to graphdb.properties file."
  type             = "SecureString"
  value_wo         = filebase64(var.graphdb_properties_path)
  value_wo_version = local.graphdb_ssm_versions.properties
  key_id           = var.parameter_store_key_arn
}

resource "aws_ssm_parameter" "graphdb_java_options" {
  count = var.graphdb_java_options != null ? 1 : 0

  name             = "/${var.resource_name_prefix}/graphdb/graphdb_java_options"
  description      = "GraphDB options to pass to GraphDB with GRAPHDB_JAVA_OPTS environment variable."
  type             = "SecureString"
  value_wo         = var.graphdb_java_options
  value_wo_version = local.graphdb_ssm_versions.java_options
  key_id           = var.parameter_store_key_arn
}
