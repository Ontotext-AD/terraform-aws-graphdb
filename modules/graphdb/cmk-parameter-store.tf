locals {
  # Kept while create_*_kms_key is true even if an external key is set, so data already encrypted with it stays readable.
  create_parameter_store_cmk = var.create_parameter_store_kms_key
}

resource "aws_kms_key" "parameter_store_cmk" {
  count = local.create_parameter_store_cmk ? 1 : 0

  is_enabled               = var.parameter_store_key_enabled
  description              = var.parameter_store_cmk_description
  customer_master_key_spec = var.parameter_store_key_spec
  enable_key_rotation      = var.parameter_store_key_rotation_enabled
  tags                     = var.parameter_store_key_tags
  deletion_window_in_days  = var.parameter_store_key_deletion_window_in_days
}

resource "aws_kms_alias" "graphdb_parameter_store_cmk_alias" {
  count = local.create_parameter_store_cmk ? 1 : 0

  name          = var.parameter_store_cmk_alias
  target_key_id = aws_kms_key.parameter_store_cmk[0].key_id
}

resource "aws_kms_key_policy" "parameter_store_cmk_policy" {
  count = local.create_parameter_store_cmk ? 1 : 0

  key_id = aws_kms_key.parameter_store_cmk[0].id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "graphdb-parameter-store-key-policy",
    "Statement" : [
      {
        # The module admin role has no IAM policy, so it stays a key administrator next to any custom admins.
        "Sid" : "AllowKeyManagement",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : distinct(concat(
            ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", aws_iam_role.param_store_key_admin_role.arn],
            length(trimspace(var.parameter_store_key_admin_arn)) > 0 ? split(",", var.parameter_store_key_admin_arn) : []
          ))
        },
        "Action" : local.kms_key_management_actions,
        "Resource" : "*"
      },
      {
        "Sid" : "AllowAccountUseViaSSM",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        # Standard parameters use Encrypt, advanced-tier parameters use GenerateDataKey, reads use Decrypt.
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "kms:ViaService" : "ssm.${var.aws_region}.amazonaws.com",
            "kms:CallerAccount" : data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        "Sid" : "AllowGraphDBRoleToDecryptParametersViaSSM",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : aws_iam_role.graphdb_iam_role.arn
        },
        "Action" : "kms:Decrypt",
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "kms:ViaService" : "ssm.${var.aws_region}.amazonaws.com"
          },
          "StringLike" : {
            "kms:EncryptionContext:PARAMETER_ARN" : "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.resource_name_prefix}/graphdb/*"
          }
        }
      }
    ]
  })
}
