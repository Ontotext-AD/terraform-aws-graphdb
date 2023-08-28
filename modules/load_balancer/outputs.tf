output "lb_arn" {
  description = "ARN of GraphDB load balancer"
  value       = aws_lb.graphdb.arn
}

output "lb_dns_name" {
  description = "DNS name of GraphDB load balancer"
  value       = aws_lb.graphdb.dns_name
}

output "lb_zone_id" {
  description = "Zone ID of GraphDB load balancer"
  value       = aws_lb.graphdb.zone_id
}

output "lb_target_group_arn" {
  description = "Target group ARN to register GraphDB nodes with"
  value       = aws_lb_target_group.graphdb.arn
}
