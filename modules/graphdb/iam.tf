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
      "arn:aws:ssm:${var.aws_region}:${var.aws_subscription_id}:*"
    ]
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
      "ec2:CreateVolume",
      "ec2:AttachVolume",
      "ec2:DescribeVolumes",
      "ec2:MonitorInstances",
      "ec2:CreateTags"
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:network-interface/*"
    ]
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
}

resource "aws_iam_role_policy" "graphdb_route53_instance_registration" {
  name   = "${var.resource_name_prefix}-route53-instance-registration"
  role   = aws_iam_role.graphdb_iam_role.id
  policy = data.aws_iam_policy_document.graphdb_route53_instance_registration.json
}

data "aws_iam_policy_document" "graphdb_route53_instance_registration" {
  statement {
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]

    resources = ["arn:aws:route53:::hostedzone/${aws_route53_zone.graphdb_zone.zone_id}"]
  }
}


resource "aws_iam_role_policy" "graphdb_s3_replication_policy_logging" {
  count  = var.logging_enable_replication ? 1 : 0
  name   = "${var.resource_name_prefix}-s3-replication_policy-logging"
  role   = aws_iam_role.graphdb_s3_replication_role.id
  policy = data.aws_iam_policy_document.graphdb_s3_replication_policy_logging.json
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

    resources = ["arn:aws:s3:::${var.graphdb_backup_bucket_name}/*"]
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
