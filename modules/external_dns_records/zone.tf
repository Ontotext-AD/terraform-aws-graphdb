data "aws_route53_zone" "existing" {
  count   = var.existing_zone_id != null && var.existing_zone_id != "" ? 1 : 0
  zone_id = var.existing_zone_id
}

locals {
  initial_vpcs = var.private_zone ? (
    length(var.vpc_associations) > 0
    ? var.vpc_associations
    : (var.vpc_id != null ? [{ vpc_id = var.vpc_id, vpc_region = var.vpc_region }] : [])
  ) : []
}

resource "aws_route53_zone" "this" {
  count         = var.existing_zone_id != null && var.existing_zone_id != "" ? 0 : 1
  name          = var.zone_name
  force_destroy = var.force_destroy

  dynamic "vpc" {
    for_each = local.initial_vpcs
    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = try(vpc.value.vpc_region, null)
    }
  }
}
