locals {
  create_sns_cmk              = var.enable_sns_kms_key && var.sns_external_kms_key == ""
  create_sns_availability_cmk = var.enable_sns_kms_key && var.sns_availability_external_kms_key == ""
}

data "aws_region" "current" {}

# Region of the availability tests provider.
data "aws_region" "availability" {
  provider = aws.useast1
}

data "aws_caller_identity" "current" {}

# Creates/manages KMS CMK for the main deployment region
resource "aws_kms_key" "sns_cmk" {
  count = local.create_sns_cmk ? 1 : 0

  is_enabled               = var.key_enabled
  description              = var.sns_cmk_description
  customer_master_key_spec = var.key_spec
  enable_key_rotation      = var.rotation_enabled
  deletion_window_in_days  = var.deletion_window_in_days
}

# Add an alias to the key
resource "aws_kms_alias" "sns_cmk_alias" {
  count = local.create_sns_cmk ? 1 : 0

  name          = var.cmk_key_alias
  target_key_id = aws_kms_key.sns_cmk[0].key_id
}

locals {
  # Key management only. Data-plane (Encrypt/Decrypt/GenerateDataKey) is granted only to the services that need it.
  sns_kms_key_management_actions = [
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

  sns_topic_arn              = "arn:aws:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${var.resource_name_prefix}-graphdb-notifications"
  sns_availability_topic_arn = "arn:aws:sns:${data.aws_region.availability.region}:${data.aws_caller_identity.current.account_id}:${var.resource_name_prefix}-route53-sns-notifications"

  # The module admin role has no IAM policy, so it stays a key administrator next to any custom admins.
  sns_kms_key_admin_principals = distinct(concat(length(trimspace(var.sns_key_admin_arn)) > 0 ? split(",", var.sns_key_admin_arn) : [], [aws_iam_role.sns_key_admin_role.arn]))
}

resource "aws_kms_key_policy" "sns_cmk_policy" {
  count = local.create_sns_cmk ? 1 : 0

  key_id = aws_kms_key.sns_cmk[0].id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "kms-key-policy-access-control",
    "Statement" : [
      {
        "Sid" : "AllowAccountKeyManagement",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : local.sns_kms_key_management_actions,
        "Resource" : "*"
      },
      {
        "Sid" : "AllowKeyAdministrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : local.sns_kms_key_admin_principals
        },
        "Action" : local.sns_kms_key_management_actions,
        "Resource" : "*"
      },
      {
        "Sid" : "AllowSNSServiceToUseKey",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "sns.amazonaws.com"
        },
        "Action" : [
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:SourceAccount" : data.aws_caller_identity.current.account_id
          },
          "ArnLike" : {
            "aws:SourceArn" : local.sns_topic_arn
          }
        }
      },
      {
        "Sid" : "AllowAccountPublishViaSNS",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "kms:ViaService" : "sns.${data.aws_region.current.region}.amazonaws.com",
            "kms:CallerAccount" : data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        "Sid" : "AllowCloudWatchAlarmsToUseKey",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "cloudwatch.amazonaws.com"
        },
        "Action" : [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:SourceAccount" : data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Creates/manages KMS CMK for the us-east-1 region (Availability SNS Topic)
resource "aws_kms_key" "sns_availability_topic_key" {
  count = local.create_sns_availability_cmk ? 1 : 0

  provider                 = aws.useast1
  is_enabled               = var.key_enabled
  description              = var.sns_cmk_description
  customer_master_key_spec = var.key_spec
  enable_key_rotation      = var.rotation_enabled
  deletion_window_in_days  = var.deletion_window_in_days
}

# Add an alias to the key
resource "aws_kms_alias" "sns_availability_cmk_alias" {
  count = local.create_sns_availability_cmk ? 1 : 0

  provider      = aws.useast1
  name          = var.cmk_availability_key_alias
  target_key_id = aws_kms_key.sns_availability_topic_key[0].key_id
}

resource "aws_kms_key_policy" "sns_availability_cmk_policy" {
  provider = aws.useast1
  count    = local.create_sns_availability_cmk ? 1 : 0
  key_id   = aws_kms_key.sns_availability_topic_key[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowAccountKeyManagement",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = local.sns_kms_key_management_actions,
        Resource  = "*"
      },
      {
        Sid       = "AllowKeyAdministrators",
        Effect    = "Allow",
        Principal = { AWS = local.sns_kms_key_admin_principals },
        Action    = local.sns_kms_key_management_actions,
        Resource  = "*"
      },
      {
        Sid       = "AllowSNSServiceToUseKey",
        Effect    = "Allow",
        Principal = { Service = "sns.amazonaws.com" },
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          },
          ArnLike = {
            "aws:SourceArn" = local.sns_availability_topic_arn
          }
        }
      },
      {
        Sid       = "AllowAccountPublishViaSNS",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "kms:ViaService"    = "sns.${data.aws_region.availability.region}.amazonaws.com",
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
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
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}
