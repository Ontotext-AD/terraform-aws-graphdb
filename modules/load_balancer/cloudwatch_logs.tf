data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  lb_access_logs_arn      = local.is_alb ? aws_lb.graphdb_alb[0].arn : aws_lb.graphdb_nlb[0].arn
  lb_access_logs_log_type = local.is_alb ? "ALB_ACCESS_LOGS" : "NLB_ACCESS_LOGS"
}

# LB Access Logs - CloudWatch Logs destination

resource "aws_cloudwatch_log_group" "graphdb_lb_access_logs" {
  count = var.lb_enable_access_logs && var.lb_access_logs_enable_cloudwatch_delivery ? 1 : 0

  name              = "/aws/vendedlogs/${var.resource_name_prefix}-lb-access-logs"
  retention_in_days = var.lb_access_logs_cloudwatch_retention_in_days
}

resource "aws_cloudwatch_log_delivery_source" "graphdb_lb_access_logs" {
  count = var.lb_enable_access_logs && var.lb_access_logs_enable_cloudwatch_delivery ? 1 : 0

  name         = "${var.resource_name_prefix}-lb-access-logs"
  log_type     = local.lb_access_logs_log_type
  resource_arn = local.lb_access_logs_arn
}

data "aws_iam_policy_document" "graphdb_lb_access_logs_delivery" {
  count = var.lb_enable_access_logs && var.lb_access_logs_enable_cloudwatch_delivery ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["${aws_cloudwatch_log_group.graphdb_lb_access_logs[0].arn}:log-stream:*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "graphdb_lb_access_logs" {
  count = var.lb_enable_access_logs && var.lb_access_logs_enable_cloudwatch_delivery ? 1 : 0

  policy_name     = "${var.resource_name_prefix}-lb-access-logs-delivery"
  policy_document = data.aws_iam_policy_document.graphdb_lb_access_logs_delivery[0].json
}

resource "aws_cloudwatch_log_delivery_destination" "graphdb_lb_access_logs" {
  count = var.lb_enable_access_logs && var.lb_access_logs_enable_cloudwatch_delivery ? 1 : 0

  name = "${var.resource_name_prefix}-lb-access-logs"

  delivery_destination_configuration {
    destination_resource_arn = aws_cloudwatch_log_group.graphdb_lb_access_logs[0].arn
  }
}

resource "aws_cloudwatch_log_delivery" "graphdb_lb_access_logs" {
  count = var.lb_enable_access_logs && var.lb_access_logs_enable_cloudwatch_delivery ? 1 : 0

  delivery_source_name     = aws_cloudwatch_log_delivery_source.graphdb_lb_access_logs[0].name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.graphdb_lb_access_logs[0].arn

  depends_on = [aws_cloudwatch_log_resource_policy.graphdb_lb_access_logs]

  # Recreate the delivery when the source changes, e.g. on an ALB <-> NLB switch
  lifecycle {
    replace_triggered_by = [
      aws_cloudwatch_log_delivery_source.graphdb_lb_access_logs,
      aws_cloudwatch_log_delivery_destination.graphdb_lb_access_logs,
    ]
  }
}
