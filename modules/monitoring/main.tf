locals {
  # For cloudwatch_agent_config:
  # 1. The templatefile() function renders the "cloudwatch_agent_config.json.tpl" file using the
  #    provided variable (var.resource_name_prefix). This produces the final JSON configuration as a text string.
  # 2. The md5() function then calculates a 32-character hexadecimal hash of that rendered configuration.
  # 3. substr(..., 0, 12) extracts the first 12 characters of the MD5 hash. These 12 characters form a shorter
  #    fingerprint that still reflects the contents of the rendered template.
  # 4. Finally, parseint(..., 16) converts this hexadecimal substring into a decimal number (using base 16 for conversion).
  # This final decimal number acts as a dynamically computed version for the Cloudwatch Agent configuration,
  # ensuring that if the configuration changes (or the input variable changes), the version number will change,
  # and Terraform will update the corresponding SSM parameter.
  graphdb_ssm_versions = {
    cloudwatch_agent_config = parseint(
      substr(md5(templatefile("${path.module}/cloudwatch_agent_config.json.tpl", {
        name = var.resource_name_prefix
      })), 0, 12),
      16
    )
  }
}

# Cloudwatch log group which hosts the logs

resource "aws_cloudwatch_log_group" "graphdb_log_group" {
  name              = var.resource_name_prefix
  retention_in_days = var.cloudwatch_log_group_retention_in_days
}

# SSM Parameter which hosts the config for the cloudwatch agent

resource "aws_ssm_parameter" "graphdb_cloudwatch_agent_config" {
  name        = "/${var.resource_name_prefix}/graphdb/CWAgent/Config"
  description = "Cloudwatch Agent Configuration"
  type        = var.ssm_parameter_store_ssm_parameter_type
  tier        = var.ssm_parameter_store_ssm_parameter_tier
  key_id      = var.parameter_store_kms_key_arn

  value_wo         = templatefile("${path.module}/cloudwatch_agent_config.json.tpl", { name : var.resource_name_prefix })
  value_wo_version = local.graphdb_ssm_versions.cloudwatch_agent_config

  depends_on = [aws_cloudwatch_log_group.graphdb_log_group]
}

# Cloudwatch Dashboard

resource "aws_cloudwatch_dashboard" "graphdb_dashboard" {
  dashboard_name = var.resource_name_prefix
  dashboard_body = var.enable_availability_tests ? templatefile("${path.module}/graphdb_dashboard.json", {
    health_check_id                   = aws_route53_health_check.graphdb_availability_check[0].id
    resource_name_prefix              = var.resource_name_prefix
    aws_region                        = var.aws_region
    route53_availability_check_region = var.route53_availability_check_region
    }) : templatefile("${path.module}/graphdb_dashboard_no_availability.json", {
    resource_name_prefix = var.resource_name_prefix
    aws_region           = var.aws_region
  })
}

