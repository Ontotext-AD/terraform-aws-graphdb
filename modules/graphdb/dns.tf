resource "aws_route53_zone" "graphdb_zone" {
  count = var.route53_existing_zone_id == null ? 1 : 0

  name = var.route53_zone_dns_name

  # Allows Terraform to destroy it
  force_destroy = true

  vpc {
    vpc_id = var.vpc_id
  }
}
