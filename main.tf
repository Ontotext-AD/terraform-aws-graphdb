data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "./modules/vpc"

  count = var.create_vpc ? 1 : 0

  resource_name_prefix     = var.resource_name_prefix
  vpc_dns_hostnames        = var.vpc_dns_hostnames
  vpc_dns_support          = var.vpc_dns_support
  vpc_private_subnet_cidrs = var.vpc_private_subnet_cidrs
  vpc_public_subnet_cidrs  = var.vpc_public_subnet_cidrs
  vpc_cidr_block           = var.vpc_cidr_block
  single_nat_gateway       = var.single_nat_gateway
  enable_nat_gateway       = var.enable_nat_gateway
}

module "backup" {
  source = "./modules/backup"

  count = var.deploy_backup ? 1 : 0

  resource_name_prefix = var.resource_name_prefix
  iam_role_id          = module.graphdb.iam_role_id
}

module "load_balancer" {
  source = "./modules/load_balancer"

  resource_name_prefix          = var.resource_name_prefix
  vpc_id                        = module.vpc[0].vpc_id
  lb_subnets                    = var.lb_internal ? module.vpc[0].private_subnet_ids : module.vpc[0].public_subnet_ids
  lb_internal                   = var.lb_internal
  lb_deregistration_delay       = var.lb_deregistration_delay
  lb_health_check_path          = var.lb_health_check_path
  lb_health_check_interval      = var.lb_health_check_interval
  lb_enable_deletion_protection = var.prevent_resource_deletion
  lb_tls_certificate_arn        = var.lb_tls_certificate_arn
  lb_tls_policy                 = var.lb_tls_policy
}

locals {
  graphdb_target_group_arns = concat(
    [module.load_balancer.lb_target_group_arn]
  )
}

module "monitoring" {
  source = "./modules/monitoring"
  providers = {
    aws.monitoring = aws.monitoring
  }

  count = var.deploy_monitoring ? 1 : 0

  resource_name_prefix                   = var.resource_name_prefix
  aws_region                             = var.aws_region
  route53_availability_check_region      = var.monitoring_route53_health_check_aws_region
  cloudwatch_alarms_actions_enabled      = var.monitoring_actions_enabled
  sns_topic_endpoint                     = var.deploy_monitoring ? var.monitoring_sns_topic_endpoint : null
  sns_endpoint_auto_confirms             = var.monitoring_endpoint_auto_confirms
  sns_protocol                           = var.monitoring_sns_protocol
  cloudwatch_log_group_retention_in_days = var.monitoring_log_group_retention_in_days
  route53_availability_request_url       = module.load_balancer.lb_dns_name
  route53_availability_measure_latency   = var.monitoring_route53_measure_latency
}

module "graphdb" {
  source = "./modules/graphdb"

  resource_name_prefix = var.resource_name_prefix
  aws_region           = data.aws_region.current.name
  aws_subscription_id  = data.aws_caller_identity.current.account_id

  # Networking

  allowed_inbound_cidrs     = var.allowed_inbound_cidrs_lb
  allowed_inbound_cidrs_ssh = var.allowed_inbound_cidrs_ssh
  graphdb_subnets           = module.vpc[0].private_subnet_ids
  graphdb_target_group_arns = local.graphdb_target_group_arns
  vpc_id                    = module.vpc[0].vpc_id

  # Network Load Balancer

  lb_subnets          = var.lb_internal ? module.vpc[0].private_subnet_ids : module.vpc[0].public_subnet_ids
  graphdb_lb_dns_name = module.load_balancer.lb_dns_name

  # Identity

  iam_instance_profile = module.graphdb.iam_instance_profile
  iam_role_id          = module.graphdb.iam_role_id

  # GraphDB Configurations

  graphdb_admin_password  = var.graphdb_admin_password
  graphdb_cluster_token   = var.graphdb_cluster_token
  graphdb_properties_path = var.graphdb_properties_path
  graphdb_java_options    = var.graphdb_java_options
  graphdb_license_path    = var.graphdb_license_path

  # VMs

  ec2_instance_type   = var.ec2_instance_type
  graphdb_node_count  = var.graphdb_node_count
  ec2_userdata_script = module.graphdb.graphdb_userdata_base64_encoded
  ec2_key_name        = var.ec2_key_name

  # Backup Configuration

  deploy_backup          = var.deploy_backup
  backup_schedule        = var.backup_schedule
  backup_retention_count = var.backup_retention_count
  backup_bucket_name     = var.deploy_backup == false ? "" : module.backup[0].bucket_name

  # VM Image

  ami_id          = var.ami_id
  graphdb_version = var.graphdb_version

  # Managed Disks

  device_name           = var.device_name
  ebs_volume_type       = var.ebs_volume_type
  ebs_volume_size       = var.ebs_volume_size
  ebs_volume_iops       = var.ebs_volume_iops
  ebs_volume_throughput = var.ebs_volume_throughput
  ebs_kms_key_arn       = var.ebs_kms_key_arn

  # DNS

  route53_zone_id       = module.graphdb.route53_zone_id
  route53_zone_dns_name = var.route53_zone_dns_name

  # User data scripts
  deploy_monitoring = var.deploy_monitoring
}
