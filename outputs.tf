output "graphdb_lb_dns_name" {
  description = "DNS name of GraphDB load balancer"
  value       = module.load_balancer.lb_dns_name
}
