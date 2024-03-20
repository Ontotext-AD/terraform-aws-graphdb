data "aws_region" "current" {}

module "vpc" {
  source = "./modules/vpc"

  count = var.create_vpc ? 1 : 0

  azs                      = var.azs
  resource_name_prefix     = var.resource_name_prefix
  vpc_dns_hostnames        = var.vpc_dns_hostnames
  vpc_dns_support          = var.vpc_dns_support
  vpc_private_subnet_cidrs = var.vpc_private_subnet_cidrs
  vpc_public_subnet_cidrs  = var.vpc_public_subnet_cidrs
  vpc_cidr_block           = var.vpc_cidr_block
  single_nat_gateway       = var.single_nat_gateway
  enable_nat_gateway       = var.enable_nat_gateway
}

module "iam" {
  source = "./modules/iam"

  resource_name_prefix        = var.resource_name_prefix
  permissions_boundary        = var.permissions_boundary
  user_supplied_iam_role_name = var.user_supplied_iam_role_name
}

module "dns" {
  source = "./modules/dns"

  vpc_id               = module.vpc[0].vpc_id
  resource_name_prefix = var.resource_name_prefix
  zone_dns_name        = var.zone_dns_name
  iam_role_id          = module.iam.iam_role_id
}

module "backup" {
  source = "./modules/backup"

  resource_name_prefix = var.resource_name_prefix
  iam_role_id          = module.iam.iam_role_id
}

module "config" {
  source = "./modules/config"

  resource_name_prefix   = var.resource_name_prefix
  graphdb_license_path   = var.graphdb_license_path
  graphdb_lb_dns_name    = module.load_balancer.lb_dns_name
  graphdb_admin_password = var.graphdb_admin_password
  graphdb_cluster_token  = var.graphdb_cluster_token
}

module "load_balancer" {
  source = "./modules/load_balancer"

  vpc_id = module.vpc[0].vpc_id

  resource_name_prefix          = var.resource_name_prefix
  lb_subnets                    = var.lb_internal ? module.vpc[0].private_subnet_ids : module.vpc[0].public_subnet_ids
  lb_internal                   = var.lb_internal
  lb_deregistration_delay       = var.lb_deregistration_delay
  lb_health_check_path          = var.lb_health_check_path
  lb_health_check_interval      = var.lb_health_check_interval
  lb_enable_deletion_protection = var.prevent_resource_deletion
  lb_tls_certificate_arn        = var.lb_tls_certificate_arn
  lb_tls_policy                 = var.lb_tls_policy
}

module "user_data" {
  source = "./modules/user_data"

  aws_region                  = data.aws_region.current.name
  resource_name_prefix        = var.resource_name_prefix
  user_supplied_userdata_path = var.user_supplied_userdata_path
  device_name                 = var.device_name

  backup_schedule        = var.backup_schedule
  backup_retention_count = var.backup_retention_count
  backup_bucket_name     = module.backup.bucket_name

  ebs_volume_type       = var.ebs_volume_type
  ebs_volume_size       = var.ebs_volume_size
  ebs_volume_iops       = var.ebs_volume_iops
  ebs_volume_throughput = var.ebs_volume_throughput
  ebs_kms_key_arn       = var.ebs_kms_key_arn

  zone_id       = module.dns.zone_id
  zone_dns_name = var.zone_dns_name

  instance_type = var.instance_type

  depends_on = [
    module.config
  ]
}

locals {
  graphdb_target_group_arns = concat(
    [module.load_balancer.lb_target_group_arn]
  )
}

module "vm" {
  source = "./modules/vm"

  allowed_inbound_cidrs     = var.allowed_inbound_cidrs_lb
  allowed_inbound_cidrs_ssh = var.allowed_inbound_cidrs_ssh
  iam_instance_profile      = module.iam.iam_instance_profile
  iam_role_id               = module.iam.iam_role_id
  instance_type             = var.instance_type
  key_name                  = var.key_name
  lb_subnets                = var.lb_internal ? module.vpc[0].private_subnet_ids : module.vpc[0].public_subnet_ids
  node_count                = var.node_count
  resource_name_prefix      = var.resource_name_prefix
  userdata_script           = module.user_data.graphdb_userdata_base64_encoded
  ami_id                    = var.ami_id
  graphdb_version           = var.graphdb_version
  graphdb_subnets           = module.vpc[0].private_subnet_ids
  graphdb_target_group_arns = local.graphdb_target_group_arns
  vpc_id                    = module.vpc[0].vpc_id
}

module "monitoring" {
  source                            = "./modules/monitoring"
  aws_region                        = var.monitoring_aws_region
  resource_name_prefix              = var.resource_name_prefix
  actions_enabled                   = var.monitoring_actions_enabled
  sns_topic_endpoint                = var.monitoring_sns_topic_endpoint
  endpoint_auto_confirms            = var.monitoring_endpoint_auto_confirms
  sns_protocol                      = var.monitoring_sns_protocol
  log_group_retention_in_days       = var.monitoring_log_group_retention_in_days
  web_test_availability_request_url = module.load_balancer.lb_dns_name
  measure_latency                   = var.monitoring_route53_measure_latency
}
