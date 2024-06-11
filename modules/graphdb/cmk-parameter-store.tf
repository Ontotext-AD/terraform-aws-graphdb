resource "aws_kms_key" "graphdb_parameter_store_cmk" {
  count = var.enable_graphdb_parameter_store_kms_key ? 1 : 0

  description              = var.graphdb_parameter_store_cmk_description
  customer_master_key_spec = var.graphdb_parameter_store_key_spec
  is_enabled               = var.graphdb_parameter_store_key_enabled
  enable_key_rotation      = var.graphdb_parameter_store_key_rotation_enabled
  tags                     = var.graphdb_parameter_store_key_tags
  deletion_window_in_days  = var.graphdb_parameter_store_key_deletion_window_in_days

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : [
          "kms:CreateAlias",
          "kms:CreateKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DeleteAlias",
          "kms:ListResourceTags",
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
          "kms:ScheduleKeyDeletion",
          "kms:DisableKeyRotation"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow Parameter Store Use of the Key",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ssm.amazonaws.com"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.graphdb_parameter_store_key_admin_arn != "" ? var.graphdb_parameter_store_key_admin_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"

        },
        "Action" : [
          "kms:CreateAlias",
          "kms:DeleteAlias",
          "kms:DescribeKey",
          "kms:GetKeyPolicy",
          "kms:GetKeyRotationStatus",
          "kms:ListResourceTags",
          "kms:ListAliases",
          "kms:ListGrants",
          "kms:ListKeyPolicies",
          "kms:ListKeys",
          "kms:PutKeyPolicy",
          "kms:UpdateAlias",
          "kms:EnableKeyRotation",
          "kms:DisableKeyRotation"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_kms_alias" "graphdb_parameter_store_cmk_alias" {
  count = var.enable_graphdb_parameter_store_kms_key ? 1 : 0

  name          = "alias/graphdb-parameter-store-cmk"
  target_key_id = aws_kms_key.graphdb_parameter_store_cmk[0].key_id
}
