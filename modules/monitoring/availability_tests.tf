# Since Route 53 is global service all the resources will be deployed in us-east-1

# SNS Topic for the Route53 Health Check Alarm

resource "aws_sns_topic" "graphdb_route53_sns_topic" {
  count = var.enable_availability_tests ? 1 : 0

  provider          = aws.useast1
  name              = "${var.resource_name_prefix}-route53-sns-notifications"
  kms_master_key_id = var.sns_external_kms_key != "" ? var.sns_external_kms_key : (var.enable_sns_kms_key ? aws_kms_key.sns_cmk[0].arn : var.sns_default_kms_key)
}

resource "aws_sns_topic_subscription" "graphdb_route53_sns_topic_subscription" {
  count = var.enable_availability_tests ? 1 : 0

  provider               = aws.useast1
  topic_arn              = aws_sns_topic.graphdb_route53_sns_topic[0].id
  protocol               = var.sns_protocol
  endpoint               = var.sns_topic_endpoint
  endpoint_auto_confirms = var.sns_endpoint_auto_confirms
}

# Route 53 Availability Check
resource "aws_route53_health_check" "graphdb_availability_check" {
  count = var.enable_availability_tests ? 1 : 0

  provider          = aws.useast1
  failure_threshold = var.route53_availability_timeout
  fqdn              = var.route53_availability_request_url != "" ? var.route53_availability_request_url : var.lb_dns_name
  port              = var.lb_tls_certificate_arn != "" ? var.route53_availability_https_port : var.route53_availability_http_port
  request_interval  = var.route53_availability_frequency
  regions           = var.route53_availability_regions
  resource_path     = var.graphdb_node_count == 1 ? "/protocol" : "/rest/cluster/node/status"
  type              = var.route53_availability_http_string_type
  measure_latency   = var.route53_availability_measure_latency
}

# Availability Alert
resource "aws_cloudwatch_metric_alarm" "graphdb_availability_alert" {
  count = var.enable_availability_tests ? 1 : 0

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
  alarm_actions       = [aws_sns_topic.graphdb_route53_sns_topic[0].arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.graphdb_availability_check[0].id
  }
}
