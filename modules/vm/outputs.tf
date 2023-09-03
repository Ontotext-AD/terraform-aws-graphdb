output "asg_name" {
  description = "Name of autoscaling group"
  value       = aws_autoscaling_group.graphdb.name
}

output "launch_template_id" {
  description = "ID of launch template for GraphDB autoscaling group"
  value       = aws_launch_template.graphdb.id
}

output "graphdb_sg_id" {
  description = "Security group ID of GraphDB cluster"
  value       = aws_security_group.graphdb.id
}
