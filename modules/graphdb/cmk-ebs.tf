resource "aws_kms_key" "graphdb_ebs_cmk" {
  count = var.enable_graphdb_ebs_kms_key ? 1 : 0

  description              = var.graphdb_ebs_cmk_description
  customer_master_key_spec = var.graphdb_ebs_key_spec
  is_enabled               = var.graphdb_ebs_key_enabled
  enable_key_rotation      = var.graphdb_ebs_key_rotation_enabled
  tags                     = var.graphdb_ebs_key_tags
  deletion_window_in_days  = var.graphdb_ebs_key_deletion_window_in_days

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "ebs-key-policy",
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
        "Resource" : "*"
      },
      {
        "Sid" : "Allow access for Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.graphdb_ebs_key_admin_arn != "" ? var.graphdb_ebs_key_admin_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
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
        "Resource" : "*"
      },
      {
        "Sid" : "Allow use of the key for EBS encryption",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.graphdb_ebs_key_admin_arn != "" ? var.graphdb_ebs_key_admin_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
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
        "Sid" : "Allow use of the key for EBS by EC2",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : [
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:DescribeKey"
        ]
      }
    ]
  })
}

resource "aws_kms_alias" "graphdb_ebs_cmk_alias" {
  count = var.enable_graphdb_ebs_kms_key ? 1 : 0

  name          = "alias/graphdb-ebs-cmk"
  target_key_id = aws_kms_key.graphdb_ebs_cmk[0].key_id
}

