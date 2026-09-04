output "lb_arn" {
  description = "ARN of the GraphDB load balancer"
  value       = var.lb_type == "application" ? aws_lb.graphdb_alb[0].arn : aws_lb.graphdb_nlb[0].arn
}

output "lb_dns_name" {
  description = "DNS name of the GraphDB load balancer"
  value       = var.lb_type == "application" ? aws_lb.graphdb_alb[0].dns_name : aws_lb.graphdb_nlb[0].dns_name
}

output "lb_zone_id" {
  description = "Route 53 zone ID of the GraphDB load balancer"
  value       = var.lb_type == "application" ? aws_lb.graphdb_alb[0].zone_id : aws_lb.graphdb_nlb[0].zone_id
}

output "lb_target_group_arn" {
  description = "Target group ARN of the registered GraphDB nodes"
  value       = var.lb_type == "application" ? aws_lb_target_group.graphdb_alb_tg[0].arn : aws_lb_target_group.graphdb_nlb_tg[0].arn
}

output "lb_access_logs_cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group receiving LB access logs (if enabled)"
  value       = try(aws_cloudwatch_log_group.graphdb_lb_access_logs[0].arn, null)
}
