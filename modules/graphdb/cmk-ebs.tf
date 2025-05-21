resource "aws_kms_key" "ebs_cmk" {
  count = var.create_ebs_kms_key ? 1 : 0

  is_enabled               = var.ebs_key_enabled
  description              = var.ebs_cmk_description
  customer_master_key_spec = var.ebs_key_spec
  enable_key_rotation      = var.ebs_key_rotation_enabled
  tags                     = var.ebs_key_tags
  deletion_window_in_days  = var.ebs_key_deletion_window_in_days
}

resource "aws_kms_alias" "ebs_cmk_alias" {
  count = var.create_ebs_kms_key ? 1 : 0

  name          = var.ebs_cmk_alias
  target_key_id = aws_kms_key.ebs_cmk[0].key_id
}

resource "aws_kms_key_policy" "ebs_cmk_policy" {
  count = var.create_ebs_kms_key ? 1 : 0

  key_id = aws_kms_key.ebs_cmk[0].id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "graphdb-ebs-key-policy",
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
        "Sid" : "Allow access to the key for Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" = length(trimspace(var.ebs_key_admin_arn)) > 0 ? split(",", var.ebs_key_admin_arn) : [aws_iam_role.ebs_key_admin_role.arn]
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
        "Resource" : aws_kms_key.ebs_cmk[0].arn
      },
      {
        "Sid" : "Allow use of the key for EBS",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:GenerateDataKeyWithoutPlaintext*",
          "kms:DescribeKey*"
        ],
        "Resource" : aws_kms_key.ebs_cmk[0].arn
      },
      {
        "Sid" : "Allow the GraphDB IAM Role to have access to the EBS key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : aws_iam_role.graphdb_iam_role.arn
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:CreateGrant",
          "kms:DescribeKey",
          "kms:ListGrants",
          "kms:ReEncrypt*",
          "kms:GetKeyPolicy",
          "kms:ListAliases",
          "kms:ListKeys",
          "kms:RetireGrant",
          "kms:RevokeGrant",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:EnableKey",
          "kms:DisableKey"
        ],
        "Resource" : aws_kms_key.ebs_cmk[0].arn
      }
    ]
  })
}
