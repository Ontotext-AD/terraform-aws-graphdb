locals {
  # Kept while create_*_kms_key is true even if an external key is set, so data already encrypted with it stays readable.
  create_s3_cmk = var.create_s3_kms_key
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

resource "aws_kms_key_policy" "s3_cmk_policy" {
  count = local.create_s3_cmk ? 1 : 0

  key_id = aws_kms_key.s3_cmk[0].id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "graphdb-s3-key-policy",
    "Statement" : [
      {
        # Key management only. Data-plane (Encrypt/Decrypt/GenerateDataKey) and grant creation are granted separately.
        # The module admin role has no IAM policy, so it stays a key administrator next to any custom admins.
        "Sid" : "AllowKeyManagement",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : distinct(concat(
            ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", aws_iam_role.graphdb_s3_key_admin_role.arn],
            length(trimspace(var.s3_kms_key_admin_arn)) > 0 ? split(",", var.s3_kms_key_admin_arn) : []
          ))
        },
        "Action" : [
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
        ],
        "Resource" : "*"
      },
      {
        # S3 needs GenerateDataKey for writes and Decrypt for reads. Bucket Keys are enabled, so the encryption
        # context is the bucket ARN; the object ARN pattern covers objects written without a Bucket Key.
        "Sid" : "AllowUseViaS3",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            var.iam_role_arn
          ]
        },
        "Action" : [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ],
        "Resource" : "*",
        "Condition" : {
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
      }
    ]
  })
}
