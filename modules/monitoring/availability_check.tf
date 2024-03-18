# Route 53 Availability Check

resource "aws_route53_health_check" "graphdb_availability_check" {
  failure_threshold       = var.web_test_timeout
  fqdn                    = var.web_test_availability_request_url
  port                    = var.web_test_port
  request_interval        = var.web_test_frequency
  regions                 = var.web_availability_regions
  resource_path           = var.web_test_availability_path
  search_string           = var.web_test_availability_content_match
  type                    = var.route53_http_string_type
  measure_latency         = var.measure_latency
  cloudwatch_alarm_region = var.aws_region
}
