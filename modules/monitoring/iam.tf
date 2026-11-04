locals {
  # Account root by default: any principal whose IAM policy allows sts:AssumeRole on the role.
  key_admin_assume_role_principal_arn = var.assume_role_principal_arn != null ? var.assume_role_principal_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
}

data "aws_iam_policy_document" "sns_key_admin_role_assume" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        local.key_admin_assume_role_principal_arn
      ]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

# No IAM policy: the key policy grants all permissions.
resource "aws_iam_role" "sns_key_admin_role" {
  name               = "${var.resource_name_prefix}-sns-topic-role"
  assume_role_policy = data.aws_iam_policy_document.sns_key_admin_role_assume.json
}
