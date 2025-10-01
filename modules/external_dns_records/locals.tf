locals {
  normalized_zone_name = var.zone_name != null ? trim(var.zone_name, ".") : null

  zone_id = coalesce(
    try(data.aws_route53_zone.existing[0].zone_id, null),
    try(aws_route53_zone.this[0].zone_id, null)
  )

  zone_name = coalesce(
    try(trim(data.aws_route53_zone.existing[0].name, "."), null),
    try(trim(aws_route53_zone.this[0].name, "."), null),
    local.normalized_zone_name
  )

  a_by_name     = { for r in var.a_records_list : r.name => r }
  cname_by_name = { for r in var.cname_records_list : r.name => r }
}
