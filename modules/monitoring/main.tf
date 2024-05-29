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

  value = templatefile("${path.module}/cloudwatch_agent_config.json.tpl", { name : var.resource_name_prefix })

  depends_on = [aws_cloudwatch_log_group.graphdb_log_group]
}

# Cloudwatch Dashboard

resource "aws_cloudwatch_dashboard" "graphdb_dashboard" {
  dashboard_name = var.resource_name_prefix
  dashboard_body = templatefile("${path.module}/graphdb_dashboard.json", {
    health_check_id                   = aws_route53_health_check.graphdb_availability_check.id
    resource_name_prefix              = var.resource_name_prefix
    aws_region                        = var.aws_region
    route53_availability_check_region = var.route53_availability_check_region
  })
}


