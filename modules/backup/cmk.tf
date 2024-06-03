resource "aws_kms_key" "s3_cmk" {
  count = var.enable_s3_kms_key ? 1 : 0

  description              = "KMS key for S3 bucket encryption"
  customer_master_key_spec = var.s3_key_spec
  is_enabled               = var.s3_key_enabled
  enable_key_rotation      = var.s3_key_rotation_enabled
  tags                     = var.s3_key_tags
  deletion_window_in_days  = var.s3_key_deletion_window_in_days


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
        "Resource" : "*"
      },
      {
        "Sid" : "Allow S3 Use of the Key",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "s3.amazonaws.com"
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
          "AWS" : var.s3_key_admin_arn != "" ? var.s3_key_admin_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_kms_alias" "s3_cmk_alias" {
  count         = var.enable_s3_kms_key ? 1 : 0
  name          = "alias/s3-cmk"
  target_key_id = aws_kms_key.s3_cmk[0].key_id
}