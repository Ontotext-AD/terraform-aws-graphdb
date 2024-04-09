resource "aws_route53_zone" "graphdb_zone" {
  name = var.route53_zone_dns_name

  # Allows for Terraform to destroy it.
  force_destroy = true

  vpc {
    vpc_id = var.vpc_id
  }
}

