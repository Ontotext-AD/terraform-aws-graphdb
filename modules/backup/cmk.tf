resource "aws_kms_key" "s3_cmk" {
  count = var.create_s3_kms_key ? 1 : 0

  is_enabled               = var.s3_kms_key_enabled
  description              = var.s3_cmk_description
  customer_master_key_spec = var.s3_key_specification
  enable_key_rotation      = var.s3_key_rotation_enabled
  deletion_window_in_days  = var.s3_key_deletion_window_in_days
}

resource "aws_kms_alias" "s3_cmk_alias" {
  count = var.create_s3_kms_key ? 1 : 0

  name          = var.s3_cmk_alias
  target_key_id = aws_kms_key.s3_cmk[0].key_id
}

resource "aws_kms_key_policy" "s3_cmk_policy" {
  count = var.create_s3_kms_key ? 1 : 0

  key_id = aws_kms_key.s3_cmk[0].id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : data.aws_caller_identity.current.arn
        },
        "Action" : [
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
          "kms:DisableKeyRotation"
        ],
        "Resource" : aws_kms_key.s3_cmk[0].arn
      },
      {
        "Sid" : "Allow Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.s3_kms_key_admin_arn != "" ? var.s3_kms_key_admin_arn : "${aws_iam_role.graphdb_s3_key_admin_role.arn}"
        },
        "Action" : [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ListResourceTags",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        "Resource" : aws_kms_key.s3_cmk[0].arn
      },
      {
        "Sid" : "Allow S3 Use of the Key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.s3_kms_key_admin_arn != "" ? var.s3_kms_key_admin_arn : "${aws_iam_role.graphdb_s3_key_admin_role.arn}"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : aws_kms_key.s3_cmk[0].arn
      },
      {
        "Sid" : "Allow the GraphDB IAM role to have permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "${var.iam_role_arn}"
        },
        "Action" : [
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
          "kms:GenerateDataKey"
        ],
        "Resource" : aws_kms_key.s3_cmk[0].arn
      }
    ]
  })
}

