locals {
  create_ebs_cmk = var.create_ebs_kms_key && var.ebs_external_kms_key == ""
}

resource "aws_kms_key" "ebs_cmk" {
  count = local.create_ebs_cmk ? 1 : 0

  is_enabled               = var.ebs_key_enabled
  description              = var.ebs_cmk_description
  customer_master_key_spec = var.ebs_key_spec
  enable_key_rotation      = var.ebs_key_rotation_enabled
  tags                     = var.ebs_key_tags
  deletion_window_in_days  = var.ebs_key_deletion_window_in_days
}

resource "aws_kms_alias" "ebs_cmk_alias" {
  count = local.create_ebs_cmk ? 1 : 0

  name          = var.ebs_cmk_alias
  target_key_id = aws_kms_key.ebs_cmk[0].key_id
}

locals {
  # Key management only. Data-plane (Encrypt/Decrypt/GenerateDataKey) and grant creation are granted separately.
  # Shared with the Parameter Store CMK policy.
  kms_key_management_actions = [
    "kms:CancelKeyDeletion",
    "kms:CreateAlias",
    "kms:DeleteAlias",
    "kms:DescribeKey",
    "kms:DisableKey",
    "kms:DisableKeyRotation",
    "kms:EnableKey",
    "kms:EnableKeyRotation",
    "kms:GetKeyPolicy",
    "kms:GetKeyRotationStatus",
    "kms:ListGrants",
    "kms:ListKeyPolicies",
    "kms:ListKeyRotations",
    "kms:ListResourceTags",
    "kms:PutKeyPolicy",
    "kms:RevokeGrant",
    "kms:RotateKeyOnDemand",
    "kms:ScheduleKeyDeletion",
    "kms:TagResource",
    "kms:UntagResource",
    "kms:UpdateAlias",
    "kms:UpdateKeyDescription"
  ]

  # The module admin role has no IAM policy, so it stays a key administrator next to any custom admins.
  ebs_kms_key_admin_principals = distinct(concat(length(trimspace(var.ebs_key_admin_arn)) > 0 ? split(",", var.ebs_key_admin_arn) : [], [aws_iam_role.ebs_key_admin_role.arn]))
  # The actions EBS needs to create, attach and snapshot encrypted volumes (CreateGrant is granted separately).
  ebs_kms_key_use_actions = [
    "kms:Decrypt",
    "kms:DescribeKey",
    "kms:GenerateDataKeyWithoutPlaintext",
    "kms:ReEncrypt*"
  ]
  ebs_kms_key_via_ec2 = {
    "kms:ViaService" : "ec2.${var.aws_region}.amazonaws.com",
    "kms:CallerAccount" : data.aws_caller_identity.current.account_id
  }
}

resource "aws_kms_key_policy" "ebs_cmk_policy" {
  count = local.create_ebs_cmk ? 1 : 0

  key_id = aws_kms_key.ebs_cmk[0].id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "graphdb-ebs-key-policy",
    "Statement" : [
      {
        "Sid" : "AllowAccountKeyManagement",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : local.kms_key_management_actions,
        "Resource" : "*"
      },
      {
        "Sid" : "AllowKeyAdministrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : local.ebs_kms_key_admin_principals
        },
        "Action" : local.kms_key_management_actions,
        "Resource" : "*"
      },
      {
        "Sid" : "AllowAccountUseViaEC2",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : local.ebs_kms_key_use_actions,
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : local.ebs_kms_key_via_ec2
        }
      },
      {
        "Sid" : "AllowAccountGrantsViaEC2",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:CreateGrant",
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : local.ebs_kms_key_via_ec2,
          "Bool" : {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
      },
      {
        "Sid" : "AllowGraphDBRoleUseViaEC2",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : aws_iam_role.graphdb_iam_role.arn
        },
        "Action" : local.ebs_kms_key_use_actions,
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : local.ebs_kms_key_via_ec2
        }
      },
      {
        "Sid" : "AllowGraphDBRoleGrantsViaEC2",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : aws_iam_role.graphdb_iam_role.arn
        },
        "Action" : "kms:CreateGrant",
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : local.ebs_kms_key_via_ec2,
          "Bool" : {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
      }
    ]
  })
}
