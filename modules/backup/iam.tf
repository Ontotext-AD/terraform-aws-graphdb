data "aws_iam_policy_document" "graphdb_s3_key_admin_role_assume" {
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
        "kms.amazonaws.com",
        "ssm.amazonaws.com"
      ]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "graphdb_s3_key_admin_role_permissions" {
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
      "kms:ListGrants",
      "kms:ListKeyPolicies",
      "kms:ListKeys",
      "kms:PutKeyPolicy",
      "kms:UpdateAlias",
      "kms:EnableKeyRotation",
      "kms:ListResourceTags",
      "kms:ScheduleKeyDeletion",
      "kms:DisableKeyRotation",
      "tag:GetResources"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "graphdb_s3_key_admin_role_permissions" {
  name   = "KMSPermissionsPolicy-S3"
  role   = aws_iam_role.graphdb_s3_key_admin_role.name
  policy = data.aws_iam_policy_document.graphdb_s3_key_admin_role_permissions.json
}

resource "aws_iam_role" "graphdb_s3_key_admin_role" {
  name               = "${var.resource_name_prefix}-s3-key-admins"
  assume_role_policy = data.aws_iam_policy_document.graphdb_s3_key_admin_role_assume.json
}
