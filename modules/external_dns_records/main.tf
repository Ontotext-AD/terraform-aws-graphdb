resource "aws_route53_record" "a_records" {
  for_each        = local.a_by_name
  zone_id         = local.zone_id
  name            = (trimspace(each.key) == "" || each.key == "@") ? local.zone_name : each.key
  type            = contains(["A", "AAAA"], upper(try(each.value.type, "A"))) ? upper(try(each.value.type, "A")) : "A"
  allow_overwrite = var.allow_overwrite

  dynamic "alias" {
    for_each = try(each.value.alias, null) != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = try(alias.value.evaluate_target_health, false)
    }
  }

  ttl     = try(each.value.alias, null) == null ? try(each.value.ttl, 300) : null
  records = try(each.value.alias, null) == null ? try(each.value.records, null) : null

  lifecycle {
    precondition {
      condition     = !(try(each.value.alias, null) != null && try(length(each.value.records), 0) > 0)
      error_message = "A/AAAA record cannot have both alias and records."
    }
    precondition {
      condition     = (try(each.value.alias, null) != null) || (try(each.value.ttl, null) != null)
      error_message = "Standard A/AAAA record requires ttl."
    }
  }
}

resource "aws_route53_record" "cname_records" {
  for_each        = local.cname_by_name
  zone_id         = local.zone_id
  name            = each.key
  type            = "CNAME"
  ttl             = each.value.ttl
  records         = [each.value.record]
  allow_overwrite = var.allow_overwrite
}
