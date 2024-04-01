resource "aws_iam_instance_profile" "graphdb" {
  name_prefix = "${var.resource_name_prefix}-graphdb"
  role        = aws_iam_role.graphdb.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.graphdb.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_admin_policy" {
  role       = aws_iam_role.graphdb.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_access_policy" {
  role       = aws_iam_role.graphdb.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccessV2"
}

resource "aws_iam_role" "graphdb" {
  name_prefix        = "${var.resource_name_prefix}-graphdb-"
  assume_role_policy = data.aws_iam_policy_document.instance_role.json
}

data "aws_iam_policy_document" "instance_role" {
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

resource "aws_iam_role_policy" "instance_volume" {
  name   = "${var.resource_name_prefix}-graphdb-instance-volume"
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.instance_volume.json
}

resource "aws_iam_role_policy" "instance_volume_tagging" {
  name   = "${var.resource_name_prefix}-graphdb-instance-volume-tagging"
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.instance_volume_tagging.json
}

resource "aws_iam_role_policy_attachment" "systems-manager-policy" {
  role       = var.iam_role_id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "instance_ssm" {
  name   = "${var.resource_name_prefix}-graphdb-ssm-describe"
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.instance_ssm.json
}

data "aws_iam_policy_document" "instance_ssm" {
  statement {
    effect = "Allow"

    actions = [
      "ssm:DescribeParameters"
    ]

    resources = ["arn:aws:ssm:${var.aws_region}:${var.aws_subscription_id}:*"]
  }
}

data "aws_iam_policy_document" "instance_volume" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateVolume",
      "ec2:AttachVolume",
      "ec2:DescribeVolumes",
      "ec2:DescribeInstances",
      "route53:ListResourceRecordSets"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "instance_volume_tagging" {
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

resource "aws_iam_role_policy" "route53_instance_registration" {
  name   = "${var.resource_name_prefix}-graphdb-route53-instance-registration"
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.route53_instance_registration.json
}

data "aws_iam_policy_document" "route53_instance_registration" {
  statement {
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets"
    ]

    resources = ["arn:aws:route53:::hostedzone/${aws_route53_zone.zone.zone_id}"]
  }
}
