# Alarms

# Attempting to recover metric filter
resource "aws_cloudwatch_log_metric_filter" "graphdb_attempting_to_recover_metric_filter" {
  name           = "${var.resource_name_prefix}-attempting-to-recover"
  pattern        = "successfully replicated registration will not retry"
  log_group_name = aws_cloudwatch_log_group.graphdb_log_group.name

  metric_transformation {
    name      = "Attempting to recover through snapshot replication"
    namespace = "${var.resource_name_prefix}-graphdb"
    value     = "1"
    unit      = "Count"
  }

  depends_on = [aws_cloudwatch_log_group.graphdb_log_group]
}

# Attempting to recover alarm based on metric filter

resource "aws_cloudwatch_metric_alarm" "graphdb_attempting_to_recover_alarm" {
  alarm_name          = "al-${var.resource_name_prefix}-attempting-recover"
  alarm_description   = "Attempting to recover through snapshot replication"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = aws_cloudwatch_log_metric_filter.graphdb_attempting_to_recover_metric_filter.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.graphdb_attempting_to_recover_metric_filter.metric_transformation[0].namespace
  period              = var.period
  statistic           = "SampleCount"
  evaluation_periods  = var.evaluation_periods
  threshold           = "0"
  alarm_actions       = [aws_sns_topic.graphdb_sns_topic.arn]

  depends_on = [aws_cloudwatch_log_metric_filter.graphdb_attempting_to_recover_metric_filter]
}

# Log filter for low disk space messages in the logs

resource "aws_cloudwatch_log_metric_filter" "graphdb_low_disk_space_metric_filter" {
  name           = "al-${var.resource_name_prefix}-low-disk-space"
  pattern        = "No space left on the device"
  log_group_name = aws_cloudwatch_log_group.graphdb_log_group.name

  metric_transformation {
    name      = "Low disk space"
    namespace = "${var.resource_name_prefix}-graphdb"
    value     = "1"
    unit      = "Count"
  }

  depends_on = [aws_cloudwatch_log_group.graphdb_log_group]
}

# Alarm based on metric filter for Low Disk Space messages in the logs

resource "aws_cloudwatch_metric_alarm" "low_disk_space_alarm" {
  alarm_name          = "al-${var.resource_name_prefix}-low-disk-space"
  alarm_description   = "Low Disk Space"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = aws_cloudwatch_log_metric_filter.graphdb_low_disk_space_metric_filter.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.graphdb_low_disk_space_metric_filter.metric_transformation[0].namespace
  period              = var.period
  statistic           = "SampleCount"
  evaluation_periods  = var.evaluation_periods
  threshold           = "0"
  alarm_actions       = [aws_sns_topic.graphdb_sns_topic.arn]

  depends_on = [aws_cloudwatch_log_metric_filter.graphdb_low_disk_space_metric_filter]
}

# TODO: Currently this alarm won't work because it relies on the instance IDs which need to be parsed dynamically. The workarounds are remote state, or restructruting the current modules in order to parse the EC2 InstanceIDs from the VM module.

resource "aws_cloudwatch_metric_alarm" "graphdb_memory_utilization" {
  alarm_name          = "al-${var.resource_name_prefix}-memory-utilization"
  alarm_description   = "Alarm will trigger if Memory utilization is above 90%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.evaluation_periods
  period              = var.period
  statistic           = "Average"
  threshold           = var.al_low_memory_warning_threshold
  actions_enabled     = var.actions_enabled
  alarm_actions       = [aws_sns_topic.graphdb_sns_topic.arn]

  metric_name = "mem_used_percent"
  namespace   = "CWAgent"
  unit        = "Percent"

  //dimensions = {
  // InstanceId = data.aws_instances.filtered_instances.ids[count.index]
  // }
}

# Alarm for CPU Utilization for Autoscaling Group

resource "aws_cloudwatch_metric_alarm" "graphdb_cpu_utilization" {
  alarm_name          = "al-${var.resource_name_prefix}-cpu-utilization"
  alarm_description   = "Alarm will trigger if CPU utilization is above 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.evaluation_periods
  period              = var.period
  statistic           = "Average"
  threshold           = 80
  actions_enabled     = var.actions_enabled
  alarm_actions       = [aws_sns_topic.graphdb_sns_topic.arn]

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  unit        = "Percent"
  dimensions = {
    AutoScalingGroupName = "${var.resource_name_prefix}-graphdb"
  }
}

# Alarm for nodes disconnected
resource "aws_cloudwatch_metric_alarm" "graphdb_nodes_disconnected" {
  alarm_name          = "al-${var.resource_name_prefix}-nodes-disconnected"
  alarm_description   = "Alarm will trigger if a node has been disconnected"
  actions_enabled     = true
  evaluation_periods  = var.evaluation_periods
  datapoints_to_alarm = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"
  alarm_actions       = [aws_sns_topic.graphdb_sns_topic.arn]

  metric_query {
    id          = "q1"
    label       = "GraphDB Nodes Disconnected"
    return_data = true
    expression  = "SELECT MAX(graphdb_nodes_disconnected) FROM SCHEMA(\"${var.resource_name_prefix}-graphdb\", host)"
    period      = var.period
  }
}
