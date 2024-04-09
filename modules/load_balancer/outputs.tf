output "lb_arn" {
  description = "ARN of the GraphDB load balancer"
  value       = aws_lb.graphdb_lb.arn
}

output "lb_dns_name" {
  description = "DNS name of the GraphDB load balancer"
  value       = aws_lb.graphdb_lb.dns_name
}

output "lb_zone_id" {
  description = "Route 53 zone ID of the GraphDB load balancer"
  value       = aws_lb.graphdb_lb.zone_id
}

output "lb_target_group_arn" {
  description = "Target group ARN of the registered GraphDB nodes"
  value       = aws_lb_target_group.graphdb_lb_target_group.arn
}
