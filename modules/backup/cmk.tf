locals {
  create_s3_cmk = var.create_s3_kms_key && var.s3_external_kms_key == ""
}

resource "aws_kms_key" "s3_cmk" {
  count = local.create_s3_cmk ? 1 : 0

  is_enabled               = var.s3_kms_key_enabled
  description              = var.s3_cmk_description
  customer_master_key_spec = var.s3_key_specification
  enable_key_rotation      = var.s3_key_rotation_enabled
  deletion_window_in_days  = var.s3_key_deletion_window_in_days
}

resource "aws_kms_alias" "s3_cmk_alias" {
  count = local.create_s3_cmk ? 1 : 0

  name          = var.s3_cmk_alias
  target_key_id = aws_kms_key.s3_cmk[0].key_id
}

locals {
  # Key management only. Data-plane (Encrypt/Decrypt/GenerateDataKey) and grant creation are granted separately.
  s3_kms_key_management_actions = [
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

  # S3 needs GenerateDataKey for writes and Decrypt for reads. Bucket Keys are enabled, so the encryption
  # context is the bucket ARN; the object ARN pattern covers objects written without a Bucket Key.
  s3_kms_key_use_actions = [
    "kms:GenerateDataKey",
    "kms:Decrypt"
  ]
  s3_kms_key_use_condition = {
    "StringEquals" : {
      "kms:ViaService" : "s3.${data.aws_region.current.region}.amazonaws.com",
      "kms:CallerAccount" : data.aws_caller_identity.current.account_id
    },
    "StringLike" : {
      "kms:EncryptionContext:aws:s3:arn" : [
        aws_s3_bucket.graphdb_backup.arn,
        "${aws_s3_bucket.graphdb_backup.arn}/*"
      ]
    }
  }

  # The module admin role has no IAM policy, so it stays a key administrator next to any custom admins.
  s3_kms_key_admin_principals = distinct(concat(length(trimspace(var.s3_kms_key_admin_arn)) > 0 ? split(",", var.s3_kms_key_admin_arn) : [], [aws_iam_role.graphdb_s3_key_admin_role.arn]))
}

resource "aws_kms_key_policy" "s3_cmk_policy" {
  count = local.create_s3_cmk ? 1 : 0

  key_id = aws_kms_key.s3_cmk[0].id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "graphdb-s3-key-policy",
    "Statement" : [
      {
        "Sid" : "AllowAccountKeyManagement",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : local.s3_kms_key_management_actions,
        "Resource" : "*"
      },
      {
        "Sid" : "AllowKeyAdministrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : local.s3_kms_key_admin_principals
        },
        "Action" : local.s3_kms_key_management_actions,
        "Resource" : "*"
      },
      {
        "Sid" : "AllowAccountUseViaS3",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : local.s3_kms_key_use_actions,
        "Resource" : "*",
        "Condition" : local.s3_kms_key_use_condition
      },
      {
        "Sid" : "AllowGraphDBRoleUseViaS3",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.iam_role_arn
        },
        "Action" : local.s3_kms_key_use_actions,
        "Resource" : "*",
        "Condition" : local.s3_kms_key_use_condition
      }
    ]
  })
}
