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
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.graphdb_instance_volume.json
}

resource "aws_iam_role_policy" "graphdb_instance_volume_tagging" {
  name   = "${var.resource_name_prefix}-volume-tagging"
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.graphdb_instance_volume_tagging.json
}

resource "aws_iam_role_policy_attachment" "graphdb_systems_manager_policy" {
  role       = var.iam_role_id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "graphdb_instance_ssm_iam_role_policy" {
  name   = var.resource_name_prefix
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.graphdb_instance_ssm.json
}

data "aws_iam_policy_document" "graphdb_instance_ssm" {
  statement {
    effect = "Allow"

    actions = [
      "ssm:DescribeParameters"
    ]

    resources = ["arn:aws:ssm:${var.aws_region}:${var.aws_subscription_id}:*"]
  }
}

data "aws_iam_policy_document" "graphdb_instance_volume" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateVolume",
      "ec2:AttachVolume",
      "ec2:DescribeVolumes",
      "ec2:DescribeInstances",
      "ec2:MonitorInstances",
      "route53:ListResourceRecordSets"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "graphdb_instance_volume_tagging" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateTags"
    ]

    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*"
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
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.graphdb_route53_instance_registration.json
}

data "aws_iam_policy_document" "graphdb_route53_instance_registration" {
  statement {
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets"
    ]

    resources = ["arn:aws:route53:::hostedzone/${aws_route53_zone.graphdb_zone.zone_id}"]
  }
}
