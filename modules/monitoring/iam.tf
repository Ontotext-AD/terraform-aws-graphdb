data "aws_iam_policy_document" "graphdb_sns_key_admin_role_assume" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "${data.aws_caller_identity.current.arn}"
      ]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }

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

data "aws_iam_policy_document" "graphdb_sns_key_admin_role_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "kms:CreateAlias",
      "kms:CreateKey",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DeleteAlias",
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListAliases",

      "kms:UpdateKeyDescription",
      "kms:ListGrants",
      "kms:ListKeyPolicies",
      "kms:ListKeys",
      "kms:PutKeyPolicy",
      "kms:UpdateAlias",
      "kms:EnableKeyRotation",
      "kms:ListResourceTags",
      "kms:ScheduleKeyDeletion",
      "kms:DisableKeyRotation",
      "tag:GetResources",
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "graphdb_sns_key_admin_role_permissions" {
  name   = "KMSPermissionsPolicy-SNS"
  role   = aws_iam_role.graphdb_sns_key_admin_role.name
  policy = data.aws_iam_policy_document.graphdb_sns_key_admin_role_permissions.json
}

resource "aws_iam_role" "graphdb_sns_key_admin_role" {
  name               = "${var.resource_name_prefix}-sns-topic-role"
  assume_role_policy = data.aws_iam_policy_document.graphdb_sns_key_admin_role_assume.json
}
