resource "aws_iam_instance_profile" "graphdb" {
  name_prefix = "${var.resource_name_prefix}-graphdb"
  role        = var.user_supplied_iam_role_name != null ? var.user_supplied_iam_role_name : aws_iam_role.instance_role[0].name
}

resource "aws_iam_role" "instance_role" {
  count                = var.user_supplied_iam_role_name != null ? 0 : 1
  name_prefix          = "${var.resource_name_prefix}-graphdb-"
  permissions_boundary = var.permissions_boundary
  assume_role_policy   = data.aws_iam_policy_document.instance_role.json
}

data "aws_iam_policy_document" "instance_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "s3_crud" {
  count  = var.user_supplied_iam_role_name != null ? 0 : 1
  name   = "${var.resource_name_prefix}-graphdb-s3-crud"
  role   = aws_iam_role.instance_role[0].id
  policy = data.aws_iam_policy_document.s3_crud.json
}

resource "aws_iam_role_policy" "instance_volume" {
  count  = var.user_supplied_iam_role_name != null ? 0 : 1
  name   = "${var.resource_name_prefix}-graphdb-instance-volume"
  role   = aws_iam_role.instance_role[0].id
  policy = data.aws_iam_policy_document.instance_volume.json
}

resource "aws_iam_role_policy" "instance_volume_tagging" {
  count  = var.user_supplied_iam_role_name != null ? 0 : 1
  name   = "${var.resource_name_prefix}-graphdb-instance-volume-tagging"
  role   = aws_iam_role.instance_role[0].id
  policy = data.aws_iam_policy_document.instance_volume_tagging.json
}

resource "aws_iam_role_policy" "route53_instance_registration" {
  count  = var.user_supplied_iam_role_name != null ? 0 : 1
  name   = "${var.resource_name_prefix}-graphdb-route53-instance-registration"
  role   = aws_iam_role.instance_role[0].id
  policy = data.aws_iam_policy_document.route53_instance_registration.json
}

data "aws_iam_policy_document" "s3_crud" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListObjects",
      "s3:PutObject",
      "s3:GetAccelerateConfiguration",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload"
    ]
    resources = [
      # the exact ARN is needed for the list bucket action, star for put,get,delete
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }
}

data "aws_iam_policy_document" "instance_volume" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateVolume",
      "ec2:AttachVolume",
      "ec2:DescribeVolumes",
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
      "arn:aws:ec2:*:*:snapshot/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values = [
        "CreateVolume",
        "CreateSnapshot",
      ]
    }
  }
}

data "aws_iam_policy_document" "route53_instance_registration" {
  statement {
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets"
    ]

    resources = ["arn:aws:route53:::hostedzone/${var.route53_zone_id}"]
  }
}

resource "aws_iam_role_policy_attachment" "systems-manager-policy" {
  role       = aws_iam_role.instance_role[0].id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM user needed for the backup upload to S3

resource "aws_iam_user" "this" {
  name = "${var.resource_name_prefix}-backup"
  path = "/system/"
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}

resource "aws_iam_user_policy" "this" {
  name   = "${var.resource_name_prefix}-s3backups"
  user   = aws_iam_user.this.name
  policy = data.aws_iam_policy_document.s3_crud.json
}