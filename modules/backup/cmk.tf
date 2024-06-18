resource "aws_kms_key" "s3_cmk" {
  count = var.enable_s3_kms_key ? 1 : 0

  description              = var.s3_cmk_description
  customer_master_key_spec = var.s3_key_spec
  is_enabled               = var.s3_key_enabled
  enable_key_rotation      = var.s3_key_rotation_enabled
  tags                     = var.s3_key_tags
  deletion_window_in_days  = var.s3_key_deletion_window_in_days

}

resource "aws_kms_key_policy" "s3_cmk_policy" {
  key_id = aws_kms_key.s3_cmk[0].id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.s3_cmk[0].id}"
      },
      {
        "Sid" : "Allow S3 Use of the Key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.s3_key_admin_arn != "" ? var.s3_key_admin_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.s3_cmk[0].id}"
      },
      {
        "Sid" : "Allow Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          #"AWS" : var.s3_key_admin_arn != "" ? var.s3_key_admin_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          "AWS" : var.s3_key_admin_arn != "" ? var.s3_key_admin_arn : "${aws_iam_role.graphdb_s3_key_admin_role.arn}"

        },
        "Action" : "kms:*",
        "Resource" : "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.s3_cmk[0].id}"
      }
    ]
  })
}

resource "aws_kms_alias" "s3_cmk_alias" {
  count         = var.enable_s3_kms_key ? 1 : 0
  name          = "alias/s3-cmk"
  target_key_id = aws_kms_key.s3_cmk[0].key_id
}