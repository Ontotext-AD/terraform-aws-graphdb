data "aws_region" "current" {}

module "iam" {
  source = "./modules/iam"

  permissions_boundary        = var.permissions_boundary
  resource_name_prefix        = var.resource_name_prefix
  user_supplied_iam_role_name = var.user_supplied_iam_role_name
  s3_bucket_name              = module.s3.backup_bucket_name
}

module "config" {
  source = "./modules/config"

  resource_name_prefix = var.resource_name_prefix
  graphdb_license_path = var.graphdb_license_path
  graphdb_lb_dns_name  = module.load_balancer.lb_dns_name
}

module "dns" {
  source = "./modules/dns"

  vpc_id        = var.vpc_id
  zone_dns_name = var.zone_dns_name
}

module "load_balancer" {
  source = "./modules/load_balancer"

  vpc_id                        = var.vpc_id
  resource_name_prefix          = var.resource_name_prefix
  lb_subnets                    = var.lb_internal ? var.private_subnet_ids : var.public_subnet_ids
  lb_internal                   = var.lb_internal
  lb_deregistration_delay       = var.lb_deregistration_delay
  lb_health_check_path          = var.lb_health_check_path
  lb_health_check_interval      = var.lb_health_check_interval
  lb_enable_deletion_protection = var.prevent_resource_deletion
}

module "user_data" {
  source = "./modules/user_data"

  aws_region                  = data.aws_region.current.name
  resource_name_prefix        = var.resource_name_prefix
  user_supplied_userdata_path = var.user_supplied_userdata_path
  graphdb_version             = var.graphdb_version
  device_name                 = var.device_name
  backup_schedule             = var.backup_schedule
  backup_retention_count      = var.backup_retention_count
  backup_iam_key_id           = module.iam.backups_bucket_key_id
  backup_iam_key_secret       = module.iam.backups_bucket_key_secret

  ebs_volume_type       = var.ebs_volume_type
  ebs_volume_size       = var.ebs_volume_size
  ebs_volume_iops       = var.ebs_volume_iops
  ebs_volume_throughput = var.ebs_volume_throughput
  ebs_kms_key_arn       = var.ebs_kms_key_arn

  zone_id       = module.dns.zone_id
  zone_dns_name = var.zone_dns_name

  depends_on = [
    module.config,
  ]
}

module "s3" {
  source = "./modules/s3"

  resource_name_prefix = var.resource_name_prefix
  access_log_bucket    = var.s3_access_log_bucket
}

locals {
  graphdb_target_group_arns = concat(
    [module.load_balancer.lb_target_group_arn],
  )
}

module "vm" {
  source = "./modules/vm"

  allowed_inbound_cidrs     = var.allowed_inbound_cidrs_lb
  allowed_inbound_cidrs_ssh = var.allowed_inbound_cidrs_ssh
  aws_iam_instance_profile  = module.iam.aws_iam_instance_profile
  common_tags               = var.common_tags
  instance_type             = var.instance_type
  key_name                  = var.key_name
  lb_subnets                = var.lb_internal ? var.private_subnet_ids : var.public_subnet_ids
  node_count                = var.node_count
  resource_name_prefix      = var.resource_name_prefix
  userdata_script           = module.user_data.graphdb_userdata_base64_encoded
  user_supplied_ami_id      = var.user_supplied_ami_id
  graphdb_subnets           = var.private_subnet_ids
  graphdb_target_group_arns = local.graphdb_target_group_arns
  vpc_id                    = var.vpc_id
}
