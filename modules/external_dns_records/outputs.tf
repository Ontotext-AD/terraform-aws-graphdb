output "zone_id" {
  description = "Route 53 Zone ID."
  value       = local.zone_id
}

output "zone_name" {
  description = "Route 53 Zone name."
  value       = local.zone_name
}

output "name_servers" {
  description = "Authoritative name servers (public zones only)."
  value = var.private_zone ? [] : (
    var.existing_zone_id != null && var.existing_zone_id != ""
    ? try(data.aws_route53_zone.existing[0].name_servers, [])
    : try(aws_route53_zone.this[0].name_servers, [])
  )
}

output "a_record_fqdns" {
  description = "FQDNs of A/AAAA records."
  value       = try({ for k, v in aws_route53_record.a_records : k => replace(v.fqdn, "\\100.", "") }, {})
}

output "cname_record_fqdns" {
  description = "FQDNs of CNAME records."
  value       = try({ for k, v in aws_route53_record.cname_records : k => replace(v.fqdn, "\\100.", "") }, {})
}
