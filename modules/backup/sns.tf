resource "aws_sns_topic" "graphdb_sns_topic" {
  name              = "${var.resource_name_prefix}-graphdb-notifications"
  kms_master_key_id = var.create_s3_kms_key ? aws_kms_key.s3_cmk[0].arn : "alias/aws/sns"
}

# SNS Topic subscription