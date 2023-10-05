resource "aws_route53_zone" "zone" {
  name = var.zone_dns_name

  # Allows for Terraform to destroy it.
  force_destroy = true

  vpc {
    vpc_id = var.vpc_id
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
