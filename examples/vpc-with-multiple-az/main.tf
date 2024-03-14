provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./aws-vpc"

  azs                  = var.azs
  resource_name_prefix = var.resource_name_prefix
}

module "graphdb" {
  source = "../../"

  resource_name_prefix = var.resource_name_prefix

  monitoring_aws_region                  = var.monitoring_aws_region
  monitoring_log_group_retention_in_days = var.monitoring_log_group_retention_in_days
  monitoring_sns_topic_endpoint          = var.monitoring_sns_topic_endpoint

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  # Allow everyone on the internet to make requests to the load balancer
  allowed_inbound_cidrs_lb = ["0.0.0.0/0"]
  graphdb_license_path     = var.graphdb_license_path

  prevent_resource_deletion = false

  instance_type   = var.instance_type
  ami_id          = var.ami_id
  graphdb_version = var.graphdb_version
}
