
locals {
  # Account root by default: any principal whose IAM policy allows sts:AssumeRole on the role.
  assume_role_principal_arn = var.assume_role_principal_arn != null ? var.assume_role_principal_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
}

resource "aws_iam_instance_profile" "graphdb_iam_instance_profile" {
  name_prefix = "${var.resource_name_prefix}-instance-profile"
  role        = aws_iam_role.graphdb_iam_role.name
}

resource "aws_iam_role_policy_attachment" "graphdb_cloudwatch_agent_policy" {
  role       = aws_iam_role.graphdb_iam_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "graphdb_cloudwatch_admin_policy" {
  role       = aws_iam_role.graphdb_iam_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
}

resource "aws_iam_role_policy_attachment" "graphdb_cloudwatch_access_policy" {
  role       = aws_iam_role.graphdb_iam_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccessV2"
}

# Log groups are managed by Terraform. Without this, the CloudWatch agent on a terminating node recreates
# a log group Terraform just deleted, and the next apply fails with ResourceAlreadyExistsException.
resource "aws_iam_role_policy" "graphdb_deny_log_group_creation" {
  name   = "${var.resource_name_prefix}-deny-log-group-creation"
  role   = aws_iam_role.graphdb_iam_role.id
  policy = data.aws_iam_policy_document.graphdb_deny_log_group_creation.json
}

data "aws_iam_policy_document" "graphdb_deny_log_group_creation" {
  statement {
    effect = "Deny"

    actions = [
      "logs:CreateLogGroup"
    ]

    resources = [
      "arn:aws:logs:${var.aws_region}:${var.aws_subscription_id}:log-group:${var.resource_name_prefix}*"
    ]
  }
}

resource "aws_iam_role" "graphdb_iam_role" {
  name_prefix        = var.resource_name_prefix
  assume_role_policy = data.aws_iam_policy_document.graphdb_instance_role.json
}

data "aws_iam_policy_document" "graphdb_instance_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "graphdb_instance_volume" {
  name   = "${var.resource_name_prefix}-instance-volume"
  role   = aws_iam_role.graphdb_iam_role.id
  policy = data.aws_iam_policy_document.graphdb_instance_volume.json
}

resource "aws_iam_role_policy" "graphdb_instance_volume_tagging" {
  name   = "${var.resource_name_prefix}-volume-tagging"
  role   = aws_iam_role.graphdb_iam_role.id
  policy = data.aws_iam_policy_document.graphdb_instance_volume_tagging.json
}

resource "aws_iam_role_policy_attachment" "graphdb_systems_manager_policy" {
  role       = aws_iam_role.graphdb_iam_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "graphdb_instance_ssm_iam_role_policy" {
  name   = "${var.resource_name_prefix}-describe-ssm_params"
  role   = aws_iam_role.graphdb_iam_role.id
  policy = data.aws_iam_policy_document.graphdb_instance_ssm.json
}

data "aws_iam_policy_document" "graphdb_instance_ssm" {
  statement {
    effect = "Allow"

    actions = [
      "ssm:DescribeParameters"
    ]

    resources = [
      "arn:aws:ssm:${var.aws_region}:${var.aws_subscription_id}:/${var.resource_name_prefix}/graphdb/*"
    ]
  }

  # Decrypt the GraphDB SecureString parameters, only through SSM. Needed for keys whose policy delegates to IAM.
  statement {
    sid     = "DecryptGraphDBParametersViaSSM"
    effect  = "Allow"
    actions = ["kms:Decrypt"]

    resources = [
      "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.aws_region}.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:PARAMETER_ARN"
      values   = ["arn:aws:ssm:${var.aws_region}:${var.aws_subscription_id}:parameter/${var.resource_name_prefix}/graphdb/*"]
    }
  }
}

resource "aws_iam_role_policy" "graphdb_describe_resources_iam_role_policy" {
  name   = "${var.resource_name_prefix}-describe-resources"
  role   = aws_iam_role.graphdb_iam_role.id
  policy = data.aws_iam_policy_document.graphdb_describe_resources.json
}

data "aws_iam_policy_document" "graphdb_describe_resources" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstances",
      "autoscaling:DescribeInstanceRefreshes",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeScalingActivities"
    ]

    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "graphdb_instance_volume" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeVolumes",
      "ec2:MonitorInstances"
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:network-interface/*"
    ]
  }

  # Create and attach encrypted data volumes, only through EC2. Needed for keys whose policy delegates to IAM.
  statement {
    sid    = "EBSKeyUseViaEC2"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncrypt*"
    ]

    resources = [
      "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ec2.${var.aws_region}.amazonaws.com"]
    }
  }

  statement {
    sid     = "EBSKeyGrantsViaEC2"
    effect  = "Allow"
    actions = ["kms:CreateGrant"]

    resources = [
      "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ec2.${var.aws_region}.amazonaws.com"]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }

  # Read and write backups, only through S3. Needed for keys whose policy delegates to IAM.
  statement {
    sid    = "BackupKeyUseViaS3"
    effect = "Allow"

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]

    resources = [
      "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${var.aws_region}.amazonaws.com"]
    }
  }
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateVolume"
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*"
    ]

    condition {
      test     = "StringEquals"
      values   = [var.deployment_restriction_tag]
      variable = "aws:RequestTag/DeployTag"
    }

    condition {
      test     = "StringEquals"
      values   = ["${var.resource_name_prefix}-graphdb-data"]
      variable = "aws:RequestTag/Name"
    }

    condition {
      test     = "ForAllValues:StringEquals"
      values   = ["Name", "DeployTag"]
      variable = "aws:TagKeys"
    }

  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:AttachVolume",
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
    ]

    condition {
      test     = "StringEquals"
      values   = [var.deployment_restriction_tag]
      variable = "aws:ResourceTag/DeployTag"
    }
  }
}

data "aws_iam_policy_document" "graphdb_instance_volume_tagging" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateTags"
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:snapshot/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values = [
        "CreateVolume",
        "CreateSnapshot"
      ]
    }
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateTags"
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/DeployTag"
      values = [
        var.deployment_restriction_tag
      ]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/Name"
      values = [
        "${var.resource_name_prefix}:*"
      ]
    }
  }
}
resource "aws_iam_role_policy" "graphdb_route53_instance_registration" {
  count = var.graphdb_node_count > 1 ? 1 : 0

  name   = "${var.resource_name_prefix}-route53-instance-registration"
  role   = aws_iam_role.graphdb_iam_role.id
  policy = data.aws_iam_policy_document.graphdb_route53_instance_registration[count.index].json
}

data "aws_iam_policy_document" "graphdb_route53_instance_registration" {
  count = var.graphdb_node_count > 1 ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]

    resources = [
      "arn:aws:route53:::hostedzone/${aws_route53_zone.graphdb_zone != [] ? aws_route53_zone.graphdb_zone[count.index].zone_id : var.route53_existing_zone_id}"
    ]
  }
}

data "aws_iam_policy_document" "graphdb_s3_replication_policy_logging" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = ["arn:aws:s3:::${var.graphdb_logging_bucket_name}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["arn:aws:s3:::${var.graphdb_logging_bucket_name}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]

    resources = ["arn:aws:s3:::${var.graphdb_logging_replication_bucket_name}/*"]
  }
}

resource "aws_iam_role_policy" "graphdb_s3_replication_policy_backup" {
  count  = var.backup_enable_replication ? 1 : 0
  name   = "${var.resource_name_prefix}-s3-replication_policy-backup"
  role   = aws_iam_role.graphdb_s3_replication_role.id
  policy = data.aws_iam_policy_document.graphdb_s3_replication_policy_backup.json
}

data "aws_iam_policy_document" "graphdb_s3_replication_policy_backup" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = ["arn:aws:s3:::${var.graphdb_backup_bucket_name}"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["arn:aws:s3:::${var.graphdb_backup_bucket_name}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]

    resources = ["arn:aws:s3:::${var.graphdb_backup_replication_bucket_name}/*"]
  }

  # Backups are SSE-KMS: decrypt them from the backup bucket, encrypt the replicas with the replica key.
  # With a Bucket Key the encryption context is the bucket ARN, otherwise the object ARN.
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["arn:aws:kms:${var.aws_region}:${var.aws_subscription_id}:key/*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${var.aws_region}.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["arn:aws:s3:::${var.graphdb_backup_bucket_name}", "arn:aws:s3:::${var.graphdb_backup_bucket_name}/*"]
    }
  }

  dynamic "statement" {
    for_each = var.graphdb_backup_replica_kms_key_arn != "" ? [split(":", var.graphdb_backup_replica_kms_key_arn)[3]] : []

    content {
      effect    = "Allow"
      actions   = ["kms:Encrypt", "kms:Decrypt"]
      resources = [var.graphdb_backup_replica_kms_key_arn]

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["s3.${statement.value}.amazonaws.com"]
      }

      condition {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:s3:arn"
        values   = ["arn:aws:s3:::${var.graphdb_backup_replication_bucket_name}", "arn:aws:s3:::${var.graphdb_backup_replication_bucket_name}/*"]
      }
    }
  }
}

data "aws_iam_policy_document" "graphdb_s3_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "graphdb_s3_replication_role" {
  name               = "${var.resource_name_prefix}-replication-role"
  assume_role_policy = data.aws_iam_policy_document.graphdb_s3_assume_role.json
}

data "aws_iam_policy_document" "ebs_key_admin_role_assume" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        local.assume_role_principal_arn
      ]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

# No IAM policy: the key policy grants all permissions.
resource "aws_iam_role" "ebs_key_admin_role" {
  name               = "${var.resource_name_prefix}-ebs-key-admin"
  assume_role_policy = data.aws_iam_policy_document.ebs_key_admin_role_assume.json
}

# No IAM policy: the key policy grants all permissions.
resource "aws_iam_role" "param_store_key_admin_role" {
  name               = "${var.resource_name_prefix}-param-store-key-admin"
  assume_role_policy = data.aws_iam_policy_document.param_store_key_admin_role_assume.json
}

data "aws_iam_policy_document" "param_store_key_admin_role_assume" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        local.assume_role_principal_arn
      ]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "additional_policies" {
  for_each   = toset(var.additional_policy_arns)
  role       = aws_iam_role.graphdb_iam_role.id
  policy_arn = each.value
}
