provider "aws" {
  region = var.aws_region
  default_tags {
    tags = merge(
      {
        Release_Name = var.resource_name_prefix
        Name         = "${var.resource_name_prefix}"
      },
      var.common_tags
    )
  }

  dynamic "assume_role" {
    for_each = var.assume_role_arn != null ? [1] : []
    content {
      role_arn     = var.assume_role_arn
      session_name = var.assume_role_session_name
      external_id  = var.assume_role_external_id
    }
  }
}

provider "aws" {
  region = var.monitoring_route53_health_check_aws_region
  alias  = "useast1"
  default_tags {
    tags = merge(
      {
        Release_Name = var.resource_name_prefix
        Name         = "${var.resource_name_prefix}"
        Environment  = var.environment_name
        App_Name     = var.app_name
      },
      var.common_tags
    )
  }
  dynamic "assume_role" {
    for_each = var.assume_role_arn != null ? [1] : []
    content {
      role_arn     = var.assume_role_arn
      session_name = var.assume_role_session_name
      external_id  = var.assume_role_external_id
    }
  }
}

provider "aws" {
  region = var.bucket_replication_destination_region
  alias  = "bucket_replication_destination_region"
  default_tags {
    tags = merge(
      {
        Release_Name = var.resource_name_prefix
        Name         = "${var.resource_name_prefix}"
      },
      var.common_tags
    )
  }
  dynamic "assume_role" {
    for_each = var.assume_role_arn != null ? [1] : []
    content {
      role_arn     = var.assume_role_arn
      session_name = var.assume_role_session_name
      external_id  = var.assume_role_external_id
    }
  }
}
