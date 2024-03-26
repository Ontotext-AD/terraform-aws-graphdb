provider "aws" {
  region = var.aws_region
  default_tags {
    tags = merge(
      {
        Release_Name = var.resource_name_prefix
        Name         = "${var.resource_name_prefix}-graphdb"
      },
      var.common_tags
    )
  }
}
