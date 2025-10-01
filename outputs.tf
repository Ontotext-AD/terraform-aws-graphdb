output "graphdb_lb_dns_name" {
  description = "DNS name of GraphDB load balancer"
  value = try(module.load_balancer[0].lb_dns_name, var.existing_lb_dns_name
  )
}

output "external_dns_a_record_fqdns" {
  description = "FQDNs for A/AAAA records."
  value       = try(module.external_dns[0].a_record_fqdns, {})
}

output "external_dns_cname_record_fqdns" {
  description = "FQDNs for CNAME records."
  value       = try(module.external_dns[0].cname_record_fqdns, {})
}
