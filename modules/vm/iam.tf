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
