# Cloudwatch log group which hosts the logs

resource "aws_cloudwatch_log_group" "graphdb_log_group" {
  provider          = aws.main
  name              = "${var.resource_name_prefix}-graphdb"
  retention_in_days = var.log_group_retention_in_days
}

# SSM Parameter which hosts the config for the cloudwatch agent

resource "aws_ssm_parameter" "graphdb_cloudwatch_agent_config" {
  provider    = aws.main
  name        = "/${var.resource_name_prefix}/graphdb/CWAgent/Config"
  description = "Cloudwatch Agent Configuration"
  type        = var.parameter_store_ssm_parameter_type
  tier        = var.parameter_store_ssm_parameter_tier

  value = templatefile("${path.module}/cloudwatch_agent_config.json.tpl", { name : var.resource_name_prefix })

  depends_on = [aws_cloudwatch_log_group.graphdb_log_group]
}

# Cloudwatch Dashboard

resource "aws_cloudwatch_dashboard" "graphdb_dashboard" {
  provider       = aws.main
  dashboard_name = "${var.resource_name_prefix}-graphdb"
  dashboard_body = templatefile("${path.module}/graphdb_dashboard.json", {
    health_check_id                   = aws_route53_health_check.graphdb_availability_check.id
    resource_name_prefix              = var.resource_name_prefix
    aws_region                        = var.aws_region
    route53_availability_check_region = var.route53_availability_check_region
  })
}


