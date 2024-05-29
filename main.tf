data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "./modules/vpc"

  count = var.create_vpc ? 1 : 0

  resource_name_prefix                            = var.resource_name_prefix
  vpc_dns_hostnames                               = var.vpc_dns_hostnames
  vpc_dns_support                                 = var.vpc_dns_support
  vpc_private_subnet_cidrs                        = var.vpc_private_subnet_cidrs
  vpc_public_subnet_cidrs                         = var.vpc_public_subnet_cidrs
  vpc_cidr_block                                  = var.vpc_cidr_block
  single_nat_gateway                              = var.single_nat_gateway
  enable_nat_gateway                              = var.enable_nat_gateway
  lb_enable_private_access                        = var.lb_enable_private_access
  network_load_balancer_arns                      = [module.load_balancer.lb_arn]
  vpc_endpoint_service_allowed_principals         = var.vpc_endpoint_service_allowed_principals
  vpc_endpoint_service_accept_connection_requests = var.vpc_endpoint_service_accept_connection_requests
  vpc_enable_flow_logs                            = var.vpc_enable_flow_logs
  vpc_flow_log_bucket_arn                         = var.vpc_enable_flow_logs && var.deploy_logging_module ? module.logging[0].graphdb_logging_bucket_arn : null
}

module "backup" {
  source = "./modules/backup"

  count = var.deploy_backup ? 1 : 0

  resource_name_prefix       = var.resource_name_prefix
  iam_role_id                = module.graphdb.iam_role_id
  s3_enable_access_logs      = var.s3_enable_access_logs
  s3_access_logs_bucket_name = var.deploy_logging_module && var.s3_enable_access_logs ? module.logging[0].graphdb_logging_bucket_name : null
}

module "logging" {
  source = "./modules/logging"

  count = var.deploy_logging_module ? 1 : 0

  resource_name_prefix                 = var.resource_name_prefix
  lb_access_logs_expiration_days       = var.deploy_logging_module && var.lb_enable_access_logs ? var.lb_access_logs_expiration_days : null
  lb_access_logs_lifecycle_rule_status = var.deploy_logging_module && var.lb_enable_access_logs ? var.lb_access_logs_lifecycle_rule_status : "Disabled"
  s3_access_logs_expiration_days       = var.deploy_logging_module && var.s3_enable_access_logs ? var.s3_access_logs_expiration_days : null
  s3_access_logs_lifecycle_rule_status = var.deploy_logging_module && var.s3_enable_access_logs ? var.s3_access_logs_lifecycle_rule_status : "Disabled"
  vpc_flow_logs_expiration_days        = var.deploy_logging_module && var.vpc_enable_flow_logs ? var.vpc_flow_logs_expiration_days : null
  vpc_flow_logs_lifecycle_rule_status  = var.deploy_logging_module && var.vpc_enable_flow_logs ? var.vpc_flow_logs_lifecycle_rule_status : "Disabled"
  expired_object_delete_marker         = var.s3_expired_object_delete_marker
  mfa_delete                           = var.s3_mfa_delete
  versioning_enabled                   = var.s3_versioning_enabled
  abort_multipart_upload               = var.s3_abort_multipart_upload
}

module "logging_replication" {
  source = "./modules/logging_replication"

  providers = {
    aws.bucket_replication_destination_region = aws.bucket_replication_destination_region
  }

  count = var.logging_enable_bucket_replication ? 1 : 0

  resource_name_prefix       = var.resource_name_prefix
  graphdb_logging_bucket_id  = var.deploy_logging_module && var.logging_enable_bucket_replication ? module.logging[0].graphdb_logging_bucket_id : null
  graphdb_logging_bucket_arn = var.deploy_logging_module && var.logging_enable_bucket_replication ? module.logging[0].graphdb_logging_bucket_arn : null
  s3_iam_role_arn            = module.graphdb.s3_iam_role_arn
  mfa_delete                 = var.s3_mfa_delete
  enable_replication         = var.s3_enable_replication_rule
  versioning_enabled         = var.s3_versioning_enabled
}

module "backup_replication" {
  source = "./modules/backup_replication"

  providers = {
    aws.bucket_replication_destination_region = aws.bucket_replication_destination_region
  }

  count = var.backup_enable_bucket_replication ? 1 : 0

  resource_name_prefix      = var.resource_name_prefix
  graphdb_backup_bucket_id  = var.deploy_backup && var.backup_enable_bucket_replication ? module.backup[0].bucket_id : null
  graphdb_backup_bucket_arn = var.deploy_backup && var.backup_enable_bucket_replication ? module.backup[0].bucket_arn : null
  s3_iam_role_arn           = module.graphdb.s3_iam_role_arn
  mfa_delete                = var.s3_mfa_delete
  enable_replication        = var.s3_enable_replication_rule
  versioning_enabled        = var.s3_versioning_enabled
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
  lb_access_logs_bucket_name    = var.lb_enable_access_logs && var.deploy_logging_module ? module.logging[0].graphdb_logging_bucket_name : null
  lb_enable_access_logs         = var.lb_enable_access_logs
}

locals {
  graphdb_target_group_arns = concat(
    [module.load_balancer.lb_target_group_arn]
  )
}

module "monitoring" {
  source = "./modules/monitoring"
  providers = {
    aws.useast1 = aws.useast1
  }

  count = var.deploy_monitoring ? 1 : 0

  resource_name_prefix              = var.resource_name_prefix
  aws_region                        = var.aws_region
  route53_availability_check_region = var.monitoring_route53_health_check_aws_region
  cloudwatch_alarms_actions_enabled = var.monitoring_actions_enabled
  sns_topic_endpoint                = var.deploy_monitoring ? var.monitoring_sns_topic_endpoint : null
  sns_endpoint_auto_confirms        = var.monitoring_endpoint_auto_confirms
  sns_protocol                      = var.monitoring_sns_protocol
  kms_master_key_id                 = var.kms_master_key_id
  cmk_description                   = var.cmk_description
  sns_key_admin_arn                 = var.sns_key_admin_arn
  enable_cmk                        = var.enable_cmk

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
  lb_enable_private_access = var.lb_internal ? var.lb_enable_private_access : false
  lb_subnets               = var.lb_internal ? module.vpc[0].private_subnet_ids : module.vpc[0].public_subnet_ids
  graphdb_lb_dns_name      = module.load_balancer.lb_dns_name

  # GraphDB Configurations

  graphdb_admin_password  = var.graphdb_admin_password
  graphdb_cluster_token   = var.graphdb_cluster_token
  graphdb_properties_path = var.graphdb_properties_path
  graphdb_java_options    = var.graphdb_java_options
  graphdb_license_path    = var.graphdb_license_path

  # VMs

  ec2_instance_type          = var.ec2_instance_type
  graphdb_node_count         = var.graphdb_node_count
  ec2_key_name               = var.ec2_key_name
  enable_detailed_monitoring = var.monitoring_enable_detailed_instance_monitoring

  # Backup Configuration

  deploy_backup          = var.deploy_backup
  backup_schedule        = var.backup_schedule
  backup_retention_count = var.backup_retention_count
  backup_bucket_name     = var.deploy_backup == false ? "" : module.backup[0].bucket_name

  # VM Image

  ami_id            = var.ami_id
  graphdb_version   = var.graphdb_version
  override_owner_id = var.override_owner_id

  # Managed Disks

  device_name           = var.device_name
  ebs_volume_type       = var.ebs_volume_type
  ebs_volume_size       = var.ebs_volume_size
  ebs_volume_iops       = var.ebs_volume_iops
  ebs_volume_throughput = var.ebs_volume_throughput
  ebs_kms_key_arn       = var.ebs_kms_key_arn

  # DNS

  route53_zone_dns_name = var.route53_zone_dns_name

  # User data scripts

  deploy_monitoring = var.deploy_monitoring

  # S3 Replication Logging Bucket Policy

  graphdb_logging_bucket_name             = var.deploy_logging_module ? module.logging[0].graphdb_logging_bucket_name : ""
  graphdb_logging_replication_bucket_name = var.deploy_logging_module && var.logging_enable_bucket_replication ? module.logging_replication[0].graphdb_logging_bucket_name : ""

  # Variables for Backup Bucket IAM Policy

  graphdb_backup_bucket_name             = var.deploy_backup ? module.backup[0].bucket_name : ""
  graphdb_backup_replication_bucket_name = var.deploy_backup && var.backup_enable_bucket_replication ? module.backup_replication[0].graphdb_backup_replication_bucket_name : ""

  # Variables for Logging Bucket IAM Policy

  logging_enable_replication = var.logging_enable_bucket_replication
  backup_enable_replication  = var.backup_enable_bucket_replication

  # ASG instance deployment options
  asg_enable_instance_refresh               = var.asg_enable_instance_refresh
  asg_instance_refresh_checkpoint_delay     = var.asg_instance_refresh_checkpoint_delay
  graphdb_enable_userdata_scripts_on_reboot = var.graphdb_enable_userdata_scripts_on_reboot
}