output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.graphdb_private_subnet[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.graphdb_public_subnet[*].id
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.graphdb_vpc.id
}