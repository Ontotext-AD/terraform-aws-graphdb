# Cloudwatch log group which hosts the logs

resource "aws_cloudwatch_log_group" "graphdb_log_group" {
  name              = "${var.resource_name_prefix}-graphdb"
  retention_in_days = var.log_group_retention_in_days
}

# SSM Parameter which hosts the config for the cloudwatch agent

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name        = "/CWAgent/Config"
  description = "Cloudwatch Agent Configuration"
  type        = "String"
  tier        = "Advanced"

  value = templatefile("${path.module}/cloudwatch_agent_config.json.tpl", { name : var.resource_name_prefix })

  depends_on = [aws_cloudwatch_log_group.graphdb_log_group]
}

# Route 53 Availability Check

resource "aws_route53_health_check" "availability_check" {
  failure_threshold       = var.web_test_timeout
  fqdn                    = var.web_test_availability_request_url
  port                    = 80
  request_interval        = var.web_test_frequency
  regions                 = var.web_availability_regions
  resource_path           = var.web_test_availability_path
  search_string           = var.web_test_availability_content_match
  type                    = "HTTP_STR_MATCH"
  measure_latency         = var.measure_latency
  cloudwatch_alarm_region = var.aws_region
}

# SNS Topic

resource "aws_sns_topic" "graphdb_sns_topic" {
  name = "${var.resource_name_prefix}-graphdb-notifications"
}

# SNS Topic subscription

resource "aws_sns_topic_subscription" "graphdb_sns_topic_subscription" {
  topic_arn              = aws_sns_topic.graphdb_sns_topic.id
  protocol               = var.sns_protocol
  endpoint               = var.sns_topic_endpoint
  endpoint_auto_confirms = true
}

# Cloudwatch Dashboard

resource "aws_cloudwatch_dashboard" "graphdb_dashboard" {
  dashboard_name = "${var.resource_name_prefix}-graphdb"
  dashboard_body = templatefile("${path.module}/graphdb_dashboard.json", {
    health_check_id      = aws_route53_health_check.availability_check.id
    resource_name_prefix = var.resource_name_prefix
    aws_region           = var.aws_region
  })
}

# Alarms

# Attempting to recover metric filter
resource "aws_cloudwatch_log_metric_filter" "attempting_to_recover_metric_filter" {
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

resource "aws_cloudwatch_metric_alarm" "attempting_to_recover_alarm" {
  alarm_name          = "al-${var.resource_name_prefix}-attempting-recover"
  alarm_description   = "Attempting to recover through snapshot replication"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = aws_cloudwatch_log_metric_filter.attempting_to_recover_metric_filter.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.attempting_to_recover_metric_filter.metric_transformation[0].namespace
  period              = 60
  statistic           = "SampleCount"
  evaluation_periods  = 1
  threshold           = "0"
  alarm_actions       = [aws_sns_topic.graphdb_sns_topic.arn]

  depends_on = [aws_cloudwatch_log_metric_filter.attempting_to_recover_metric_filter]
}

# Log filter for low disk space messages in the logs

resource "aws_cloudwatch_log_metric_filter" "low_disk_space_metric_filter" {
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
  metric_name         = aws_cloudwatch_log_metric_filter.low_disk_space_metric_filter.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.low_disk_space_metric_filter.metric_transformation[0].namespace
  period              = 60
  statistic           = "SampleCount"
  evaluation_periods  = 1
  threshold           = "0"
  alarm_actions       = [aws_sns_topic.graphdb_sns_topic.arn]

  depends_on = [aws_cloudwatch_log_metric_filter.low_disk_space_metric_filter]
}

# Availability Alert

resource "aws_cloudwatch_metric_alarm" "availability_alert" {
  alarm_name          = "al-${var.resource_name_prefix}-availability"
  alarm_description   = "Alarm will trigger if availability goes beneath 100"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "HealthCheckPercentageHealthy"
  namespace           = "AWS/Route53"
  period              = var.periods
  statistic           = "Average"
  threshold           = "100"
  actions_enabled     = var.actions_enabled
  alarm_actions       = [aws_sns_topic.graphdb_sns_topic.arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.availability_check.id
  }
}

# Currently this alarm won't work because it relies on the instance IDs which need to be parsed dynamically. The workarounds are remote state, or restructruting the current modules in order to parse the EC2 InstanceIDs from the VM module.

resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  alarm_name          = "al-${var.resource_name_prefix}-memory-utilization"
  alarm_description   = "Alarm will trigger if Memory utilization is above 90%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 60
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
  evaluation_periods  = 1
  period              = 60
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
  evaluation_periods  = 1
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
    period      = 60
  }
}



