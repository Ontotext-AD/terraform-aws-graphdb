resource "aws_route53_zone" "zone" {
  name = var.zone_dns_name

  # Allows for Terraform to destroy it.
  force_destroy = true

  vpc {
    vpc_id = var.vpc_id
  }
}

