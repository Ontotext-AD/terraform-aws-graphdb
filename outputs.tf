output "graphdb_lb_dns_name" {
  description = "DNS name of GraphDB load balancer"
  value = try(module.load_balancer[0].lb_dns_name, var.existing_lb_dns_name
  )
}
