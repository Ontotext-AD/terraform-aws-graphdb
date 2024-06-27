data "aws_region" "current" {}

resource "aws_kms_key" "graphdb_ebs_cmk" {
  count = var.create_graphdb_ebs_kms_key ? 1 : 0

  description              = var.graphdb_ebs_cmk_description
  customer_master_key_spec = var.graphdb_ebs_key_spec
  is_enabled               = var.graphdb_ebs_key_enabled
  enable_key_rotation      = var.graphdb_ebs_key_rotation_enabled
  tags                     = var.graphdb_ebs_key_tags
  deletion_window_in_days  = var.graphdb_ebs_key_deletion_window_in_days

}

resource "aws_kms_key_policy" "graphdb_ebs_cmk_policy" {
  count = var.create_graphdb_ebs_kms_key ? 1 : 0

  key_id = aws_kms_key.graphdb_ebs_cmk[0].id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "graphdb-ebs-key-policy",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.graphdb_ebs_key_admin_arn != "" ? var.graphdb_ebs_key_admin_arn : "${aws_iam_role.graphdb_ebs_key_admin_role.arn}"
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
        "Resource" : "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.graphdb_ebs_cmk[0].id}"
      },
      {
        "Sid" : "Allow access for Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.graphdb_ebs_key_admin_arn != "" ? var.graphdb_ebs_key_admin_arn : "${aws_iam_role.graphdb_ebs_key_admin_role.arn}"
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
        "Resource" : "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.graphdb_ebs_cmk[0].id}"
      },
      {
        "Sid" : "Allow use of the key for EBS encryption",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.graphdb_ebs_key_admin_arn != "" ? var.graphdb_ebs_key_admin_arn : "${aws_iam_role.graphdb_ebs_key_admin_role.arn}"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.graphdb_ebs_cmk[0].id}"
      },
      {
        "Sid" : "Allow use of the key for EBS by EC2",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "s3.amazonaws.com",
            "ebs.amazonaws.com",
            "sns.amazonaws.com",
            "ec2.amazonaws.com",
            "ssm.amazonaws.com"
          ]
        },
        "Action" : [
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:DescribeKey"
        ],
        "Resource" : "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.graphdb_ebs_cmk[0].id}"
      },
      {
        "Sid" : "Allow the current user to manage key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "${data.aws_caller_identity.current.arn}"
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
        "Resource" : "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.graphdb_ebs_cmk[0].id}"
      }
    ]
  })
}

resource "aws_kms_alias" "graphdb_ebs_cmk_alias" {
  count = var.create_graphdb_ebs_kms_key ? 1 : 0

  name          = "alias/graphdb-ebs-cmk"
  target_key_id = aws_kms_key.graphdb_ebs_cmk[0].key_id
}

