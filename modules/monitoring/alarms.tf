# Alarms

# Attempting to recover metric filter, one per node so the alarm can identify which node it happened on

resource "aws_cloudwatch_log_metric_filter" "graphdb_attempting_to_recover_metric_filter" {
  for_each = var.graphdb_node_count > 1 ? toset(local.instance_hostnames) : toset([])

  name           = "mf-${var.resource_name_prefix}-${each.key}-attempting-to-recover"
  pattern        = "Attempting to recover through snapshot replication"
  log_group_name = aws_cloudwatch_log_group.graphdb_node_log_group[each.key].name

  metric_transformation {
    name      = "Attempting to recover through snapshot replication - ${each.key}"
    namespace = var.resource_name_prefix
    value     = "1"
    unit      = "Count"
  }

  depends_on = [aws_cloudwatch_log_group.graphdb_node_log_group]
}

# Attempting to recover alarm based on metric filter, per node

resource "aws_cloudwatch_metric_alarm" "graphdb_attempting_to_recover_alarm" {
  for_each = var.graphdb_node_count > 1 ? toset(local.instance_hostnames) : toset([])

  alarm_name                = "al-${var.resource_name_prefix}-${each.key}-attempting-recover"
  alarm_description         = "Attempting to recover through snapshot replication on ${each.key}"
  comparison_operator       = "GreaterThanThreshold"
  metric_name               = aws_cloudwatch_log_metric_filter.graphdb_attempting_to_recover_metric_filter[each.key].metric_transformation[0].name
  namespace                 = aws_cloudwatch_log_metric_filter.graphdb_attempting_to_recover_metric_filter[each.key].metric_transformation[0].namespace
  period                    = var.cloudwatch_period
  statistic                 = "Maximum"
  evaluation_periods        = var.cloudwatch_evaluation_periods
  threshold                 = "1"
  alarm_actions             = [aws_sns_topic.graphdb_sns_topic.arn]
  ok_actions                = [aws_sns_topic.graphdb_sns_topic.arn]
  insufficient_data_actions = [aws_sns_topic.graphdb_sns_topic.arn]
  treat_missing_data        = "missing"

  depends_on = [aws_cloudwatch_log_metric_filter.graphdb_attempting_to_recover_metric_filter]
}

# Log filter for low disk space messages in the logs, one per node so the alarm can identify which node it happened on

resource "aws_cloudwatch_log_metric_filter" "graphdb_low_disk_space_metric_filter" {
  for_each = toset(local.instance_hostnames)

  name           = "al-${var.resource_name_prefix}-${each.key}-low-disk-space-GraphDB-disk"
  pattern        = "\"is critically low on free disk space\""
  log_group_name = aws_cloudwatch_log_group.graphdb_node_log_group[each.key].name

  metric_transformation {
    name      = "Low disk space - ${each.key}"
    namespace = var.resource_name_prefix
    value     = "1"
    unit      = "Count"
  }

  depends_on = [aws_cloudwatch_log_group.graphdb_node_log_group]
}

# Alarm based on metric filter for Low Disk Space messages in the logs, per node

resource "aws_cloudwatch_metric_alarm" "graphdb_low_disk_space_alarm" {
  for_each = toset(local.instance_hostnames)

  alarm_name                = "al-${var.resource_name_prefix}-${each.key}-low-disk-space-GraphDB-disk"
  alarm_description         = "Low Disk Space on ${each.key}"
  comparison_operator       = "GreaterThanThreshold"
  metric_name               = aws_cloudwatch_log_metric_filter.graphdb_low_disk_space_metric_filter[each.key].metric_transformation[0].name
  namespace                 = aws_cloudwatch_log_metric_filter.graphdb_low_disk_space_metric_filter[each.key].metric_transformation[0].namespace
  period                    = var.cloudwatch_period
  statistic                 = "SampleCount"
  evaluation_periods        = var.cloudwatch_evaluation_periods
  threshold                 = "1"
  alarm_actions             = [aws_sns_topic.graphdb_sns_topic.arn]
  ok_actions                = [aws_sns_topic.graphdb_sns_topic.arn]
  insufficient_data_actions = [aws_sns_topic.graphdb_sns_topic.arn]
  treat_missing_data        = "missing"

  depends_on = [aws_cloudwatch_log_metric_filter.graphdb_low_disk_space_metric_filter]
}

# Log filter for Workbench settings loading errors in the logs, one per node so the alarm can identify which node it happened on

resource "aws_cloudwatch_log_metric_filter" "graphdb_workbench_settings_error_metric_filter" {
  for_each = toset(local.instance_hostnames)

  name           = "mf-${var.resource_name_prefix}-${each.key}-workbench-settings-error"
  pattern        = "\"Error loading Workbench settings, using the defaults\""
  log_group_name = aws_cloudwatch_log_group.graphdb_node_log_group[each.key].name

  metric_transformation {
    name      = "Workbench settings loading error - ${each.key}"
    namespace = var.resource_name_prefix
    value     = "1"
    unit      = "Count"
  }

  depends_on = [aws_cloudwatch_log_group.graphdb_node_log_group]
}

# Alarm based on metric filter for Workbench settings loading errors in the logs, per node

resource "aws_cloudwatch_metric_alarm" "graphdb_workbench_settings_error_alarm" {
  for_each = toset(local.instance_hostnames)

  alarm_name                = "al-${var.resource_name_prefix}-${each.key}-workbench-settings-error"
  alarm_description         = "Error loading Workbench settings, using the defaults on ${each.key}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = aws_cloudwatch_log_metric_filter.graphdb_workbench_settings_error_metric_filter[each.key].metric_transformation[0].name
  namespace                 = aws_cloudwatch_log_metric_filter.graphdb_workbench_settings_error_metric_filter[each.key].metric_transformation[0].namespace
  period                    = var.cloudwatch_period
  statistic                 = "SampleCount"
  evaluation_periods        = var.cloudwatch_evaluation_periods
  threshold                 = "1"
  alarm_actions             = [aws_sns_topic.graphdb_sns_topic.arn]
  ok_actions                = [aws_sns_topic.graphdb_sns_topic.arn]
  insufficient_data_actions = [aws_sns_topic.graphdb_sns_topic.arn]
  treat_missing_data        = "missing"

  depends_on = [aws_cloudwatch_log_metric_filter.graphdb_workbench_settings_error_metric_filter]
}

locals {
  # Builds a list of instance hostnames

  instance_hostnames = [
    for i in range(1, var.graphdb_node_count + 1) :
    var.route53_zone_dns_name != null ?
    format("node-%d.%s", i, trim(var.route53_zone_dns_name, ".")) :
    format("node-%d", i)
  ]
}

resource "aws_cloudwatch_metric_alarm" "heap_usage_alarm" {
  for_each = toset(local.instance_hostnames)

  alarm_name                = "al-${var.resource_name_prefix}-heap-memory-usage-${each.key}"
  alarm_description         = "Triggers if ${each.key}'s heap usage exceeds threshold of its total memory"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = var.graphdb_memory_utilization_threshold
  evaluation_periods        = 1
  treat_missing_data        = "missing"
  alarm_actions             = [aws_sns_topic.graphdb_sns_topic.arn]
  ok_actions                = [aws_sns_topic.graphdb_sns_topic.arn]
  insufficient_data_actions = [aws_sns_topic.graphdb_sns_topic.arn]

  # Define the metric query for heap used memory

  metric_query {
    id = "m1"
    metric {
      namespace   = var.resource_name_prefix
      metric_name = "graphdb_heap_used_mem"
      dimensions = {
        host = each.key
      }
      stat   = "Average"
      period = 60
    }
    return_data = false
  }

  # Defines the metric query for total memory

  metric_query {
    id = "m2"
    metric {
      namespace   = "CWAgent"
      metric_name = "mem_total"
      dimensions = {
        AutoScalingGroupName = var.resource_name_prefix
      }
      stat   = "Average"
      period = 60
    }
    return_data = false
  }

  # Defines the expression to calculate heap usage percentage

  metric_query {
    id          = "e1"
    expression  = "(m1 / m2) * 100"
    label       = "Heap Usage Percentage for ${each.key}"
    return_data = true
  }
}

# Alarm for ASG Memory Used Percent

resource "aws_cloudwatch_metric_alarm" "asg_mem_used_percent" {
  alarm_name                = "al-${var.resource_name_prefix}-asg-mem-used-percent"
  alarm_description         = "ASG mem_used_percent >= ${var.graphdb_memory_utilization_threshold}%"
  namespace                 = "CWAgent"
  metric_name               = "mem_used_percent"
  statistic                 = "Average"
  unit                      = "Percent"
  period                    = var.cloudwatch_period
  evaluation_periods        = var.cloudwatch_evaluation_periods
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = var.graphdb_memory_utilization_threshold
  treat_missing_data        = "missing"
  alarm_actions             = [aws_sns_topic.graphdb_sns_topic.arn]
  ok_actions                = [aws_sns_topic.graphdb_sns_topic.arn]
  insufficient_data_actions = [aws_sns_topic.graphdb_sns_topic.arn]

  dimensions = {
    AutoScalingGroupName = var.resource_name_prefix
  }
}

# Alarm for ASG CPU Utilization

resource "aws_cloudwatch_metric_alarm" "asg_cpu_utilization" {
  alarm_name                = "al-${var.resource_name_prefix}-asg-cpu-utilization"
  alarm_description         = "ASG average CPU >= ${var.cloudwatch_cpu_utilization_threshold}%"
  namespace                 = "AWS/EC2"
  metric_name               = "CPUUtilization"
  statistic                 = "Average"
  unit                      = "Percent"
  period                    = var.cloudwatch_period
  evaluation_periods        = var.cloudwatch_evaluation_periods
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = var.cloudwatch_cpu_utilization_threshold
  treat_missing_data        = "missing"
  alarm_actions             = [aws_sns_topic.graphdb_sns_topic.arn]
  ok_actions                = [aws_sns_topic.graphdb_sns_topic.arn]
  insufficient_data_actions = [aws_sns_topic.graphdb_sns_topic.arn]

  dimensions = {
    AutoScalingGroupName = var.resource_name_prefix
  }
}

# Alarm for nodes disconnected

resource "aws_cloudwatch_metric_alarm" "graphdb_nodes_disconnected" {
  for_each = var.graphdb_node_count > 1 ? toset(local.instance_hostnames) : toset([])

  alarm_name        = "al-${var.resource_name_prefix}-${each.key}-detected-nodes-disconnected"
  alarm_description = "Alarm will trigger if ${each.key} has detected one or more disconnected cluster nodes"
  actions_enabled   = true
  # Hardcoded to 1 to ensure immediate alerting regardless of var.cloudwatch_evaluation_periods.
  evaluation_periods        = 1
  datapoints_to_alarm       = 1
  threshold                 = 1
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  treat_missing_data        = "missing"
  alarm_actions             = [aws_sns_topic.graphdb_sns_topic.arn]
  ok_actions                = [aws_sns_topic.graphdb_sns_topic.arn]
  insufficient_data_actions = [aws_sns_topic.graphdb_sns_topic.arn]

  metric_query {
    id = "q1"
    metric {
      namespace   = var.resource_name_prefix
      metric_name = "graphdb_nodes_disconnected"
      dimensions = {
        host = each.key
      }
      stat   = "Maximum"
      period = var.cloudwatch_period
    }
    return_data = true
  }
}

# Alarm for ASG Root Disk Used Percent

resource "aws_cloudwatch_metric_alarm" "asg_root_disk_used_percent" {
  alarm_name                = "al-${var.resource_name_prefix}-asg-root-disk-used-percent"
  alarm_description         = "ASG disk_used_percent on / >= 80%"
  namespace                 = "CWAgent"
  metric_name               = "disk_used_percent"
  statistic                 = "Average"
  unit                      = "Percent"
  period                    = var.cloudwatch_period
  evaluation_periods        = var.cloudwatch_evaluation_periods
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = 80
  treat_missing_data        = "missing"
  alarm_actions             = [aws_sns_topic.graphdb_sns_topic.arn]
  ok_actions                = [aws_sns_topic.graphdb_sns_topic.arn]
  insufficient_data_actions = [aws_sns_topic.graphdb_sns_topic.arn]

  dimensions = {
    AutoScalingGroupName = var.resource_name_prefix
  }
}
