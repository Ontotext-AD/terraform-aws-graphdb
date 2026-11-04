# SNS Topic

resource "aws_sns_topic" "graphdb_sns_topic" {
  name              = "${var.resource_name_prefix}-graphdb-notifications"
  kms_master_key_id = var.sns_kms_key_arn

  lifecycle {
    # KMS keys are regional; SNS cannot use a key from another region.
    precondition {
      condition     = !var.enable_sns_kms_key || !startswith(var.sns_external_kms_key, "arn:") || try(split(":", var.sns_external_kms_key)[3], "") == data.aws_region.current.region
      error_message = "sns_external_kms_key must be a key in ${data.aws_region.current.region}, the region of the notifications topic."
    }
  }
}

# SNS Topic subscription

resource "aws_sns_topic_subscription" "graphdb_sns_topic_subscription" {
  topic_arn              = aws_sns_topic.graphdb_sns_topic.id
  protocol               = var.sns_protocol
  endpoint               = var.sns_topic_endpoint
  endpoint_auto_confirms = var.sns_endpoint_auto_confirms
}
