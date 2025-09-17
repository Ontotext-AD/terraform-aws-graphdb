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

output "tgw_attachment_id" {
  description = "ID of the TGW attachment (if created)"
  value       = aws_ec2_transit_gateway_vpc_attachment.graphdb_tgw_attachment[*].id
}

output "vpc_private_route_table_ids" {
  description = "Private route table IDs"
  value       = aws_route_table.graphdb_private_route_table[*].id
}

output "tgw_rt_association_id" {
  description = "ID of the TGW route table association (if created)"
  value       = try(aws_ec2_transit_gateway_route_table_association.graphdb_tgw_association[0].id, null)
}

output "tgw_rt_propagation_id" {
  description = "ID of the TGW route table propagation (if created)"
  value       = try(aws_ec2_transit_gateway_route_table_propagation.graphdb_tgw_propagation[0].id, null)
}
