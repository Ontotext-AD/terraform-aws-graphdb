# Since Route 53 is global service all the resources will be deployed in us-east-1

# SNS Topic for the Route53 Health Check Alarm

resource "aws_sns_topic" "graphdb_route53_sns_topic" {
  provider          = aws.us-east-1
  name              = "${var.resource_name_prefix}-graphdb-route53-sns-notifications"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "graphdb_route53_sns_topic_subscription" {
  provider               = aws.us-east-1
  topic_arn              = aws_sns_topic.graphdb_route53_sns_topic.id
  protocol               = var.sns_protocol
  endpoint               = var.sns_topic_endpoint
  endpoint_auto_confirms = var.endpoint_auto_confirms
}

# Route 53 Availability Check

resource "aws_route53_health_check" "graphdb_availability_check" {
  provider          = aws.us-east-1
  failure_threshold = var.web_test_timeout
  fqdn              = var.web_test_availability_request_url
  port              = var.web_test_port
  request_interval  = var.web_test_frequency
  regions           = var.web_availability_regions
  resource_path     = var.web_test_availability_path
  search_string     = var.web_test_availability_content_match
  type              = var.route53_http_string_type
  measure_latency   = var.measure_latency
}

# Availability Alert

resource "aws_cloudwatch_metric_alarm" "graphdb_availability_alert" {
  provider            = aws.us-east-1
  alarm_name          = "al-${var.resource_name_prefix}-availability"
  alarm_description   = "Alarm will trigger if availability goes beneath 100"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "HealthCheckPercentageHealthy"
  namespace           = "AWS/Route53"
  period              = var.period
  statistic           = "Average"
  threshold           = "100"
  actions_enabled     = var.actions_enabled
  alarm_actions       = [aws_sns_topic.graphdb_route53_sns_topic.arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.graphdb_availability_check.id
  }
}
