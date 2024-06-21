data "aws_iam_policy_document" "sns_topic_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "s3.amazonaws.com",
        "ebs.amazonaws.com",
        "sns.amazonaws.com",
        "ssm.amazonaws.com"
      ]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "sns_topic_role" {
  name               = "${var.resource_name_prefix}-sns-topic-role"
  assume_role_policy = data.aws_iam_policy_document.sns_topic_role.json
}
