data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# Creates/manages KMS CMK
resource "aws_kms_key" "sns_cmk" {
  count = var.enable_sns_kms_key ? 1 : 0

  is_enabled               = var.key_enabled
  description              = var.sns_cmk_description
  customer_master_key_spec = var.key_spec
  enable_key_rotation      = var.rotation_enabled
  deletion_window_in_days  = var.deletion_window_in_days
}

# Add an alias to the key
resource "aws_kms_alias" "sns_cmk_alias" {
  count = var.enable_sns_kms_key ? 1 : 0

  name          = var.cmk_key_alias
  target_key_id = aws_kms_key.sns_cmk[0].key_id
}

resource "aws_kms_key_policy" "sns_cmk_policy" {
  count = var.enable_sns_kms_key ? 1 : 0

  key_id = aws_kms_key.sns_cmk[0].id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "kms-key-policy-access-control",
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
          "kms:DisableKeyRotation",
          "kms:GenerateDataKey"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow access for Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.sns_key_admin_arn != "" ? var.sns_key_admin_arn : aws_iam_role.sns_key_admin_role.arn
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
        "Resource" : aws_kms_key.sns_cmk[0].arn
      },
      {
        "Sid" : "Allow use of the key for SNS",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "sns.amazonaws.com",
            "ec2.amazonaws.com",
            "ssm.amazonaws.com",
            "cloudwatch.amazonaws.com"
          ]
        },
        "Action" : [
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:Decrypt",
          "kms:ReEncrypt"
        ],
        "Resource" : aws_kms_key.sns_cmk[0].arn
      }
    ]
  })
}
