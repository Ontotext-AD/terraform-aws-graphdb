output "backup_bucket_name" {
  description = "Name of the S3 bucket for storing GraphDB backups"
  value       = module.backup.bucket_name
}

output "asg_name" {
  value = module.vm.asg_name
}

output "launch_template_id" {
  value = module.vm.launch_template_id
}

output "graphdb_lb_dns_name" {
  description = "DNS name of GraphDB load balancer"
  value       = module.load_balancer.lb_dns_name
}

output "graphdb_lb_zone_id" {
  description = "Zone ID of GraphDB load balancer"
  value       = module.load_balancer.lb_zone_id
}

output "graphdb_lb_arn" {
  description = "ARN of GraphDB load balancer"
  value       = module.load_balancer.lb_arn
}

output "graphdb_target_group_arn" {
  description = "Target group ARN to register GraphDB nodes with"
  value       = module.load_balancer.lb_target_group_arn
}

output "graphdb_sg_id" {
  description = "Security group ID of GraphDB cluster"
  value       = module.vm.graphdb_sg_id
}
