# SNS Topic

resource "aws_sns_topic" "graphdb_sns_topic" {
  name              = "${var.resource_name_prefix}-graphdb-notifications"
  kms_master_key_id = var.sns_kms_key_arn
}

# SNS Topic subscription

resource "aws_sns_topic_subscription" "graphdb_sns_topic_subscription" {
  topic_arn              = aws_sns_topic.graphdb_sns_topic.id
  protocol               = var.sns_protocol
  endpoint               = var.sns_topic_endpoint
  endpoint_auto_confirms = var.sns_endpoint_auto_confirms
}
