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
}

provider "aws" {
  region = var.monitoring_route53_health_check_aws_region
  alias  = "useast1"
  default_tags {
    tags = merge(
      {
        Release_Name = var.resource_name_prefix
        Name         = "${var.resource_name_prefix}"
      },
      var.common_tags
    )
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
}
