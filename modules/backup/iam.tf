data "aws_iam_policy_document" "graphdb_s3_key_admin_role" {
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

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "graphdb_s3_key_admin_role" {
  name               = "${var.resource_name_prefix}-s3-key-admins"
  assume_role_policy = data.aws_iam_policy_document.graphdb_s3_key_admin_role.json
}