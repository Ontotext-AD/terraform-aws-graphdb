# Since Route 53 is global service all the resources will be deployed in us-east-1

# SNS Topic for the Route53 Health Check Alarm

resource "aws_sns_topic" "graphdb_route53_sns_topic" {
  provider          = aws.useast1
  name              = "${var.resource_name_prefix}-route53-sns-notifications"
  kms_master_key_id = var.enable_cmk ? aws_kms_key.cmk[0].arn : "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "graphdb_route53_sns_topic_subscription" {
  provider               = aws.useast1
  topic_arn              = aws_sns_topic.graphdb_route53_sns_topic.id
  protocol               = var.sns_protocol
  endpoint               = var.sns_topic_endpoint
  endpoint_auto_confirms = var.sns_endpoint_auto_confirms
}

# Route 53 Availability Check

resource "aws_route53_health_check" "graphdb_availability_check" {
  provider          = aws.useast1
  failure_threshold = var.route53_availability_timeout
  fqdn              = var.route53_availability_request_url
  port              = var.route53_availability_port
  request_interval  = var.route53_availability_frequency
  regions           = var.route53_availability_regions
  resource_path     = var.route53_availability_path
  search_string     = var.route53_availability_content_match
  type              = var.route53_availability_http_string_type
  measure_latency   = var.route53_availability_measure_latency
}

# Availability Alert

resource "aws_cloudwatch_metric_alarm" "graphdb_availability_alert" {
  provider            = aws.useast1
  alarm_name          = "al-${var.resource_name_prefix}-availability"
  alarm_description   = "Alarm will trigger if availability goes beneath 100"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.cloudwatch_evaluation_periods
  metric_name         = "HealthCheckPercentageHealthy"
  namespace           = "AWS/Route53"
  period              = var.cloudwatch_period
  statistic           = "Average"
  threshold           = "100"
  actions_enabled     = var.cloudwatch_alarms_actions_enabled
  alarm_actions       = [aws_sns_topic.graphdb_route53_sns_topic.arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.graphdb_availability_check.id
  }
}
