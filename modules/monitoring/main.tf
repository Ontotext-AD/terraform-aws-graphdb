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

  # Repository widgets. Cluster: leader only. graphdb_cluster_node_role is 1 (leader), 0 (follower), -1 (other);
  # (r + r*r)/2 turns it into a 1/0 leader flag (the console does not render `==` here).
  # Open repositories = number of (host, repo) series of graphdb_open_connections (only running repos report it).
  graphdb_node_indexes = range(1, var.graphdb_node_count + 1)
  graphdb_leader_role_metrics = concat(
    [for i in local.graphdb_node_indexes : [{
      expression = "SEARCH('{\"${var.resource_name_prefix}\",host} MetricName=\"graphdb_cluster_node_role\" host=\"${local.instance_hostnames[i - 1]}\"', 'Maximum', ${var.cloudwatch_period})"
      id         = "r${i}"
      visible    = false
      region     = var.aws_region
    }]],
    [for i in local.graphdb_node_indexes : [{
      expression = "(MAX(r${i}) + MAX(r${i}) * MAX(r${i})) / 2"
      id         = "f${i}"
      visible    = false
      region     = var.aws_region
    }]]
  )
  graphdb_repository_widgets = {
    active_transactions = { metric = "graphdb_active_transactions", per_node = "SUM(%s)", label = "Active transactions" }
    open_connections    = { metric = "graphdb_open_connections", per_node = "SUM(%s)", label = "Open connections" }
    open_repositories   = { metric = "graphdb_open_connections", per_node = "SUM(%s*0+1)", label = "Open repositories" }
  }
  graphdb_cluster_widget_metrics = {
    for k, w in local.graphdb_repository_widgets : k => jsonencode(concat(
      local.graphdb_leader_role_metrics,
      [for i in local.graphdb_node_indexes : [{
        expression = "SEARCH('{\"${var.resource_name_prefix}\",host,repo} MetricName=\"${w.metric}\" host=\"${local.instance_hostnames[i - 1]}\"', 'Maximum', ${var.cloudwatch_period})"
        id         = "s${i}"
        visible    = false
        region     = var.aws_region
      }]],
      [for i in local.graphdb_node_indexes : [{
        expression = format("${w.per_node}*f${i}", "s${i}")
        id         = "l${i}"
        visible    = false
        region     = var.aws_region
      }]],
      [[{
        expression = "SUM([${join(",", [for i in local.graphdb_node_indexes : "l${i}"])}])"
        id         = "leader"
        label      = w.label
        region     = var.aws_region
      }]]
    ))
  }
  graphdb_single_node_widget_metrics = {
    for k, w in local.graphdb_repository_widgets : k => k == "open_repositories" ? jsonencode([
      [{
        expression = "SEARCH('{\"${var.resource_name_prefix}\",host,repo} MetricName=\"${w.metric}\"', 'Maximum', ${var.cloudwatch_period})"
        id         = "s1"
        visible    = false
        region     = var.aws_region
      }],
      [{
        expression = "SUM(s1*0+1)"
        id         = "n1"
        label      = w.label
        region     = var.aws_region
      }]
      ]) : jsonencode([
      [{
        expression = "SELECT MAX(${w.metric}) FROM \"${var.resource_name_prefix}\" GROUP BY host, repo"
        id         = "q1"
        label      = "Query1"
        region     = var.aws_region
      }]
    ])
  }
  graphdb_repository_widget_metrics = var.graphdb_node_count > 1 ? local.graphdb_cluster_widget_metrics : local.graphdb_single_node_widget_metrics

  graphdb_availability_base_path     = var.graphdb_node_count == 1 ? "/protocol" : "/rest/cluster/node/status"
  graphdb_context_prefix             = var.lb_context_path != "" ? "/${trim(var.lb_context_path, "/")}" : ""
  graphdb_availability_resource_path = "${local.graphdb_context_prefix}${local.graphdb_availability_base_path}"
}

# Cloudwatch log group which hosts the logs

resource "aws_cloudwatch_log_group" "graphdb_log_group" {
  name              = var.resource_name_prefix
  retention_in_days = var.cloudwatch_log_group_retention_in_days
}

# Per-node log group which hosts each node's main.log, so log-based alarms can be scoped per node

resource "aws_cloudwatch_log_group" "graphdb_node_log_group" {
  for_each = toset(local.instance_hostnames)

  name              = "${var.resource_name_prefix}-${each.key}"
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
    graphdb_node_count                = var.graphdb_node_count
    dashboard_period                  = var.cloudwatch_period
    open_repositories_metrics         = local.graphdb_repository_widget_metrics.open_repositories
    active_transactions_metrics       = local.graphdb_repository_widget_metrics.active_transactions
    open_connections_metrics          = local.graphdb_repository_widget_metrics.open_connections
    }) : templatefile("${path.module}/graphdb_dashboard_no_availability.json", {
    resource_name_prefix        = var.resource_name_prefix
    aws_region                  = var.aws_region
    graphdb_node_count          = var.graphdb_node_count
    dashboard_period            = var.cloudwatch_period
    open_repositories_metrics   = local.graphdb_repository_widget_metrics.open_repositories
    active_transactions_metrics = local.graphdb_repository_widget_metrics.active_transactions
    open_connections_metrics    = local.graphdb_repository_widget_metrics.open_connections
  })
}

