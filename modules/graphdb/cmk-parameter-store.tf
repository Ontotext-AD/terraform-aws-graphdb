resource "aws_kms_key" "parameter_store_cmk" {
  count = var.create_parameter_store_kms_key ? 1 : 0

  is_enabled               = var.parameter_store_key_enabled
  description              = var.parameter_store_cmk_description
  customer_master_key_spec = var.parameter_store_key_spec
  enable_key_rotation      = var.parameter_store_key_rotation_enabled
  tags                     = var.parameter_store_key_tags
  deletion_window_in_days  = var.parameter_store_key_deletion_window_in_days
}

resource "aws_kms_alias" "graphdb_parameter_store_cmk_alias" {
  count = var.create_parameter_store_kms_key ? 1 : 0

  name          = var.parameter_store_cmk_alias
  target_key_id = aws_kms_key.parameter_store_cmk[0].key_id
}

resource "aws_kms_key_policy" "parameter_store_cmk_policy" {
  count = var.create_parameter_store_kms_key ? 1 : 0

  key_id = aws_kms_key.parameter_store_cmk[0].id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "graphdb-parameter-store-key-policy",
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
          "AWS" : var.parameter_store_key_admin_arn != "" ? var.parameter_store_key_admin_arn : aws_iam_role.param_store_key_admin_role.arn
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
          "kms:GenerateDataKey",
          "kms:ReEncrypt",
          "kms:CancelKeyDeletion",
          "kms:List*",
          "kms:Enable*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "tag:GetResources"
        ],
        "Resource" : aws_kms_key.parameter_store_cmk[0].id
      },
      {
        "Sid" : "Allow use of the key for Parameter Store",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "ssm.amazonaws.com",
            "ec2.amazonaws.com"
          ]
        },
        "Action" : [
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt"
        ],
        "Resource" : aws_kms_key.parameter_store_cmk[0].arn
      },
      {
        "Sid" : "Allow GraphDB IAM Role to use the key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : aws_iam_role.graphdb_iam_role.arn
        },
        "Action" : [
          "kms:Decrypt",
          "kms:DescribeKey"
        ],
        "Resource" : aws_kms_key.parameter_store_cmk[0].arn
      }
    ]
  })
}

