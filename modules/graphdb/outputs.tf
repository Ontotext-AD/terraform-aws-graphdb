output "iam_instance_profile" {
  description = "Instance profile to use for EC2"
  value       = aws_iam_instance_profile.graphdb_iam_instance_profile.name
}

output "iam_role_id" {
  description = "IAM role ID to use for policies"
  value       = aws_iam_role.graphdb_iam_role.id
}

output "iam_role_arn" {
  description = "IAM role ARN to use for instance"
  value       = aws_iam_role.graphdb_iam_role.arn
}

output "s3_iam_role_arn" {
  description = "IAM Role to use for replication"
  value       = aws_iam_role.graphdb_s3_replication_role.arn
}

output "s3_iam_role_name" {
  value = aws_iam_role.graphdb_s3_replication_role.name
}

output "asg_name" {
  description = "Name of autoscaling group"
  value       = aws_autoscaling_group.graphdb_auto_scalling_group.name
}

output "launch_template_id" {
  description = "ID of launch template for GraphDB autoscaling group"
  value       = aws_launch_template.graphdb.id
}

output "graphdb_sg_id" {
  description = "Security group ID of GraphDB cluster"
  value       = aws_security_group.graphdb_security_group.id
}

output "graphdb_userdata_base64_encoded" {
  description = "User data script for GraphDB VM scale set."
  value       = data.cloudinit_config.graphdb_user_data.rendered
}

output "route53_zone_id" {
  description = "ID of the private hosted zone for GraphDB DNS resolving"
  value       = aws_route53_zone.graphdb_zone.zone_id
}
