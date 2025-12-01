data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# Creates/manages KMS CMK for the main deployment region
resource "aws_kms_key" "sns_cmk" {
  count = var.enable_sns_kms_key ? 1 : 0

  is_enabled               = var.key_enabled
  description              = var.sns_cmk_description
  customer_master_key_spec = var.key_spec
  enable_key_rotation      = var.rotation_enabled
  deletion_window_in_days  = var.deletion_window_in_days
}

# Add an alias to the key
resource "aws_kms_alias" "sns_cmk_alias" {
  count = var.enable_sns_kms_key ? 1 : 0

  name          = var.cmk_key_alias
  target_key_id = aws_kms_key.sns_cmk[0].key_id
}

resource "aws_kms_key_policy" "sns_cmk_policy" {
  count = var.enable_sns_kms_key ? 1 : 0

  key_id = aws_kms_key.sns_cmk[0].id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "kms-key-policy-access-control",
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
          "kms:GenerateDataKey",
          "kms:GetKeyRotationStatus"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow access for Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" = length(trimspace(var.sns_key_admin_arn)) > 0 ? split(",", var.sns_key_admin_arn) : [aws_iam_role.sns_key_admin_role.arn]
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
        "Resource" : aws_kms_key.sns_cmk[0].arn
      },
      {
        "Sid" : "Allow use of the key for SNS",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "sns.amazonaws.com",
            "ec2.amazonaws.com",
            "ssm.amazonaws.com",
            "cloudwatch.amazonaws.com"
          ]
        },
        "Action" : [
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:Decrypt",
          "kms:ReEncrypt",
          "kms:Ecnrypt"
        ],
        "Resource" : aws_kms_key.sns_cmk[0].arn
      }
    ]
  })
}

# Creates/manages KMS CMK for the us-east-1 region (Availability SNS Topic)
resource "aws_kms_key" "sns_availability_topic_key" {
  count = var.enable_sns_kms_key ? 1 : 0

  provider                 = aws.useast1
  is_enabled               = var.key_enabled
  description              = var.sns_cmk_description
  customer_master_key_spec = var.key_spec
  enable_key_rotation      = var.rotation_enabled
  deletion_window_in_days  = var.deletion_window_in_days
}

# Add an alias to the key
resource "aws_kms_alias" "sns_availability_cmk_alias" {
  count = var.enable_sns_kms_key ? 1 : 0

  provider      = aws.useast1
  name          = var.cmk_availability_key_alias
  target_key_id = aws_kms_key.sns_availability_topic_key[0].key_id
}

resource "aws_kms_key_policy" "sns_availability_cmk_policy" {
  provider = aws.useast1
  count    = var.enable_sns_kms_key ? 1 : 0
  key_id   = aws_kms_key.sns_availability_topic_key[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "EnableIAMUserPermissions",
        Effect    = "Allow",
        Principal = { AWS = data.aws_caller_identity.current.arn },
        Action    = "kms:*",
        Resource  = "*"
      },
      {
        Sid    = "AllowAccessForKeyAdministrators",
        Effect = "Allow",
        Principal = {
          AWS = length(trimspace(var.sns_key_admin_arn)) > 0 ? split(",", var.sns_key_admin_arn) : [aws_iam_role.sns_key_admin_role.arn]
        },
        Action = [
          "kms:DescribeKey",
          "kms:EnableKeyRotation",
          "kms:GetKeyPolicy",
          "kms:PutKeyPolicy",
          "kms:List*"
        ],
        Resource = aws_kms_key.sns_availability_topic_key[0].arn
      },
      {
        Sid       = "AllowSNSServiceToUseKey",
        Effect    = "Allow",
        Principal = { Service = "sns.amazonaws.com" },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          },
          ArnLike = {
            "aws:SourceArn" = "arn:aws:sns:us-east-1:${data.aws_caller_identity.current.account_id}:${var.resource_name_prefix}-route53-sns-notifications"
          }
        }
      },
      {
        Sid       = "AllowCloudWatchForCMK",
        Effect    = "Allow",
        Principal = { Service = "cloudwatch.amazonaws.com" },
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ],
        Resource = "*"
      }
    ]
  })
}
