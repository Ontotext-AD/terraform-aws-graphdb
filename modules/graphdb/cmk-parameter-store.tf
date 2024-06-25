resource "aws_kms_key" "graphdb_parameter_store_cmk" {
  count = var.enable_graphdb_parameter_store_kms_key ? 1 : 0

  description              = var.graphdb_parameter_store_cmk_description
  customer_master_key_spec = var.graphdb_parameter_store_key_spec
  is_enabled               = var.graphdb_parameter_store_key_enabled
  enable_key_rotation      = var.graphdb_parameter_store_key_rotation_enabled
  tags                     = var.graphdb_parameter_store_key_tags
  deletion_window_in_days  = var.graphdb_parameter_store_key_deletion_window_in_days
}

resource "aws_kms_key_policy" "graphdb_parameter_store_cmk_policy" {
  count  = var.enable_graphdb_parameter_store_kms_key ? 1 : 0
  key_id = aws_kms_key.graphdb_parameter_store_cmk[0].id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "graphdb-parameter-store-key-policy",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.graphdb_parameter_store_key_admin_arn != "" ? var.graphdb_parameter_store_key_admin_arn : "${aws_iam_role.graphdb_param_store_key_admin_role.arn}"
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
        "Resource" : "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.graphdb_parameter_store_cmk[0].id}"
      },
      {
        "Sid" : "Allow access for Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.graphdb_parameter_store_key_admin_arn != "" ? var.graphdb_parameter_store_key_admin_arn : "${aws_iam_role.graphdb_param_store_key_admin_role.arn}"
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
        "Resource" : "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.graphdb_parameter_store_cmk[0].id}"
      },
      {
        "Sid" : "Allow use of the key for Parameter Store encryption",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.graphdb_parameter_store_key_admin_arn != "" ? var.graphdb_parameter_store_key_admin_arn : "${aws_iam_role.graphdb_param_store_key_admin_role.arn}"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.graphdb_parameter_store_cmk[0].id}"
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
          "kms:DescribeKey"
        ],
        "Resource" : "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.graphdb_parameter_store_cmk[0].id}"
      },
      {
        "Sid" : "Allow root user to manage key",
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
        "Resource" : "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.graphdb_parameter_store_cmk[0].id}"
      }
    ]
  })
}

resource "aws_kms_alias" "graphdb_parameter_store_cmk_alias" {
  count = var.enable_graphdb_parameter_store_kms_key ? 1 : 0

  name          = "alias/graphdb-parameter-store-cmk"
  target_key_id = aws_kms_key.graphdb_parameter_store_cmk[0].key_id
}