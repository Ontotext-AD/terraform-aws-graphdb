module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1.1"

  name                   = "${var.resource_name_prefix}-graphdb"
  cidr                   = var.vpc_cidr
  azs                    = var.azs
  enable_nat_gateway     = true
  enable_dns_hostnames   = true
  one_nat_gateway_per_az = true
  private_subnets        = var.private_subnet_cidrs
  public_subnets         = var.public_subnet_cidrs

  default_network_acl_name = "Default Network ACLs for ${var.resource_name_prefix}"
  default_network_acl_ingress = [
    {
      rule_no    = 10
      action     = "deny"
      from_port  = 22
      protocol   = "tcp"
      cidr_block = "0.0.0.0/0"
      to_port    = 22
      }, {
      rule_no    = 11
      action     = "deny"
      from_port  = 3389
      protocol   = "tcp"
      cidr_block = "0.0.0.0/0"
      to_port    = 3389
      }, {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      protocol   = -1
      cidr_block = "0.0.0.0/0"
      to_port    = 0
    }
  ]
  default_network_acl_egress = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      protocol   = -1
      cidr_block = "0.0.0.0/0"
      to_port    = 0
    }
  ]
}
