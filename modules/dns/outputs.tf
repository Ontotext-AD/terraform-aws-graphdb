output "zone_id" {
  description = "ID of the private hosted zone for GraphDB DNS resolving"
  value       = aws_route53_zone.zone.zone_id
}
