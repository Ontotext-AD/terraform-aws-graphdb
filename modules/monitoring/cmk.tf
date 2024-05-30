# Creates/manages KMS CMK
resource "aws_kms_key" "cmk" {
  count = var.enable_cmk ? 1 : 0

  description              = var.cmk_description
  customer_master_key_spec = var.key_spec
  is_enabled               = var.key_enabled
  enable_key_rotation      = var.rotation_enabled
  tags                     = var.tags
  deletion_window_in_days  = 30

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "kms-key-policy-access-control",
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
        "Sid" : "Allow access for Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          # Use 'var.sns_key_admin_arn' if available and root if not provided
          "AWS" : var.sns_key_admin_arn != "" ? var.sns_key_admin_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"

        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow use of the key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.sns_key_admin_arn != "" ? var.sns_key_admin_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# Add an alias to the key
resource "aws_kms_alias" "cmk_alias" {
  count = var.enable_cmk ? 1 : 0

  name          = "alias/${var.cmk_key_alias}"
  target_key_id = aws_kms_key.cmk[0].key_id
}

data "aws_caller_identity" "current" {}