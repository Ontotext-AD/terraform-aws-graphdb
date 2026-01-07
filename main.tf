data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_group" "iam_admin_group" {
  count      = var.iam_admin_group != "" ? 1 : 0
  group_name = var.iam_admin_group
}

module "vpc" {
  source = "./modules/vpc"

  count = var.vpc_id == "" ? 1 : 0

  resource_name_prefix                            = var.resource_name_prefix
  vpc_dns_hostnames                               = var.vpc_dns_hostnames
  vpc_dns_support                                 = var.vpc_dns_support
  vpc_private_subnet_cidrs                        = local.effective_private_subnet_cidrs
  vpc_public_subnet_cidrs                         = local.effective_public_subnet_cidrs
  vpc_cidr_block                                  = var.vpc_cidr_block
  single_nat_gateway                              = var.single_nat_gateway
  enable_nat_gateway                              = var.enable_nat_gateway
  nat_gateway_mode                                = var.nat_gateway_mode
  lb_enable_private_access                        = var.lb_enable_private_access
  network_load_balancer_arns                      = local.lb_arn_list
  vpc_endpoint_service_allowed_principals         = var.vpc_endpoint_service_allowed_principals
  vpc_endpoint_service_accept_connection_requests = var.vpc_endpoint_service_accept_connection_requests
  vpc_enable_flow_logs                            = var.vpc_enable_flow_logs
  vpc_flow_log_bucket_arn = var.vpc_enable_flow_logs && var.deploy_logging_module ? (
    module.logging[0].graphdb_logging_bucket_arn
  ) : null
  graphdb_node_count = var.graphdb_node_count

  tgw_id                       = var.tgw_id != "" ? var.tgw_id : null
  tgw_subnet_cidrs             = var.tgw_id != "" ? var.tgw_subnet_cidrs : []
  tgw_subnet_ids               = var.tgw_id != "" ? var.tgw_subnet_ids : []
  tgw_client_cidrs             = var.tgw_id != "" ? var.tgw_client_cidrs : []
  tgw_dns_support              = var.tgw_dns_support
  tgw_ipv6_support             = var.tgw_ipv6_support
  tgw_appliance_mode_support   = var.tgw_appliance_mode_support
  tgw_route_table_id           = var.tgw_id != "" ? var.tgw_route_table_id : null
  tgw_associate_to_route_table = var.tgw_id != "" ? var.tgw_associate_to_route_table : false
  tgw_enable_propagation       = var.tgw_id != "" ? var.tgw_enable_propagation : false
}

module "backup" {
  source = "./modules/backup"

  count = var.deploy_backup ? 1 : 0

  resource_name_prefix  = var.resource_name_prefix
  iam_role_id           = module.graphdb.iam_role_id
  iam_role_arn          = module.graphdb.iam_role_arn
  s3_enable_access_logs = var.s3_enable_access_logs
  s3_access_logs_bucket_name = var.deploy_logging_module && var.s3_enable_access_logs ? (
    module.logging[0].graphdb_logging_bucket_name
  ) : null
  create_s3_kms_key              = var.create_s3_kms_key
  s3_default_kms_key             = var.s3_kms_default_key
  s3_cmk_alias                   = var.s3_cmk_alias
  s3_kms_key_admin_arn           = local.s3_key_admin_arn_joined
  s3_cmk_description             = var.s3_cmk_description
  s3_key_specification           = var.s3_key_specification
  s3_kms_key_enabled             = var.s3_kms_key_enabled
  s3_key_rotation_enabled        = var.s3_key_rotation_enabled
  s3_key_deletion_window_in_days = var.s3_key_deletion_window_in_days
  s3_external_kms_key            = var.s3_external_kms_key_arn
  s3_kms_key_arn                 = local.calculated_s3_kms_key_arn
}

module "logging" {
  source = "./modules/logging"

  count = var.deploy_logging_module ? 1 : 0

  resource_name_prefix = var.resource_name_prefix
  lb_access_logs_expiration_days = var.deploy_logging_module && var.lb_enable_access_logs ? (
  var.lb_access_logs_expiration_days) : null
  lb_access_logs_lifecycle_rule_status = var.deploy_logging_module && var.lb_enable_access_logs ? (
  var.lb_access_logs_lifecycle_rule_status) : "Disabled"
  s3_access_logs_expiration_days = var.deploy_logging_module && var.s3_enable_access_logs ? (
  var.s3_access_logs_expiration_days) : null
  s3_access_logs_lifecycle_rule_status = var.deploy_logging_module && var.s3_enable_access_logs ? (
    var.s3_access_logs_lifecycle_rule_status
  ) : "Disabled"
  vpc_flow_logs_expiration_days = var.deploy_logging_module && var.vpc_enable_flow_logs ? (
    var.vpc_flow_logs_expiration_days
  ) : null
  vpc_flow_logs_lifecycle_rule_status = var.deploy_logging_module && var.vpc_enable_flow_logs ? (
    var.vpc_flow_logs_lifecycle_rule_status
  ) : "Disabled"
  expired_object_delete_marker = var.s3_expired_object_delete_marker
  mfa_delete                   = var.s3_mfa_delete
  versioning_enabled           = var.s3_versioning_enabled
  abort_multipart_upload       = var.s3_abort_multipart_upload
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

  count = var.existing_lb_arn != "" ? 0 : 1

  resource_name_prefix          = var.resource_name_prefix
  vpc_id                        = var.vpc_id != "" ? var.vpc_id : module.vpc[0].vpc_id
  lb_subnets                    = local.lb_subnets
  lb_internal                   = var.lb_internal
  lb_type                       = var.lb_type
  lb_deregistration_delay       = var.lb_deregistration_delay
  lb_health_check_path          = var.lb_health_check_path
  lb_health_check_interval      = var.lb_health_check_interval
  lb_enable_deletion_protection = var.prevent_resource_deletion
  lb_tls_certificate_arn        = var.lb_tls_certificate_arn
  lb_tls_enabled                = local.lb_tls_enabled
  lb_tls_policy                 = var.lb_tls_policy
  lb_access_logs_bucket_name    = var.lb_enable_access_logs && var.deploy_logging_module ? module.logging[0].graphdb_logging_bucket_name : null
  lb_enable_access_logs         = var.lb_enable_access_logs
  graphdb_node_count            = var.graphdb_node_count
  allowed_inbound_cidrs_lb      = var.allowed_inbound_cidrs_lb
  lb_idle_timeout               = var.lb_idle_timeout
  lb_client_keep_alive_timeout  = var.lb_client_keep_alive_timeout
  lb_enable_http2               = var.alb_enable_http2
}

module "monitoring" {
  source = "./modules/monitoring"
  providers = {
    aws.useast1 = aws.useast1
  }

  count = var.deploy_monitoring ? 1 : 0

  resource_name_prefix = var.resource_name_prefix
  aws_region           = var.aws_region

  sns_topic_endpoint                     = var.deploy_monitoring ? var.monitoring_sns_topic_endpoint : null
  sns_endpoint_auto_confirms             = var.monitoring_endpoint_auto_confirms
  sns_protocol                           = var.monitoring_sns_protocol
  sns_cmk_description                    = var.sns_cmk_description
  sns_key_admin_arn                      = local.sns_key_admin_arn_joined
  enable_sns_kms_key                     = var.create_sns_kms_key
  sns_external_kms_key                   = var.sns_external_kms_key
  rotation_enabled                       = var.sns_rotation_enabled
  deletion_window_in_days                = var.deletion_window_in_days
  key_enabled                            = var.sns_key_enabled
  key_spec                               = var.sns_key_spec
  sns_default_kms_key                    = var.sns_default_kms_key
  cmk_key_alias                          = local.cmk_key_alias
  cmk_availability_key_alias             = local.cmk_availability_key_alias
  parameter_store_kms_key_arn            = local.calculated_parameter_store_kms_key_arn
  cloudwatch_log_group_retention_in_days = var.monitoring_log_group_retention_in_days
  enable_availability_tests              = var.monitoring_enable_availability_tests

  route53_availability_check_region     = var.monitoring_route53_health_check_aws_region
  route53_availability_request_url      = var.graphdb_node_count > 1 ? var.graphdb_external_dns : module.load_balancer[0].lb_dns_name
  route53_availability_measure_latency  = var.graphdb_node_count > 1 ? var.monitoring_route53_measure_latency : false
  route53_availability_http_string_type = upper(local.calculated_protocol)
  route53_zone_dns_name                 = var.graphdb_node_count > 1 ? var.route53_zone_dns_name : null
  route53_availability_http_port        = var.monitoring_route53_availability_http_port
  route53_availability_https_port       = var.monitoring_route53_availability_https_port

  sns_kms_key_arn    = local.calculated_sns_kms_key_arn
  graphdb_node_count = var.graphdb_node_count

  lb_tls_certificate_arn = var.lb_tls_certificate_arn
  lb_dns_name            = module.load_balancer[0].lb_dns_name != "" ? module.load_balancer[0].lb_dns_name : null

  # Alarms Threshold
  cloudwatch_cpu_utilization_threshold = var.monitoring_cpu_utilization_threshold
  graphdb_memory_utilization_threshold = var.monitoring_memory_utilization_threshold
}

module "graphdb" {
  source = "./modules/graphdb"

  resource_name_prefix       = var.resource_name_prefix
  deployment_restriction_tag = var.deployment_restriction_tag
  aws_region                 = data.aws_region.current.id
  aws_subscription_id        = data.aws_caller_identity.current.account_id
  assume_role_principal_arn  = var.assume_role_principal_arn
  additional_policy_arns     = var.graphdb_additional_policy_arns

  # Networking

  allowed_inbound_cidrs     = var.allowed_inbound_cidrs_lb
  allowed_inbound_cidrs_ssh = var.allowed_inbound_cidrs_ssh
  graphdb_subnets           = local.graphdb_subnets
  graphdb_target_group_arns = local.lb_tg_arn_list
  vpc_id                    = var.vpc_id != "" ? var.vpc_id : module.vpc[0].vpc_id

  # Network Load Balancer

  lb_enable_private_access = var.lb_internal ? var.lb_enable_private_access : false
  lb_subnets               = local.lb_subnets
  graphdb_lb_dns_name      = local.lb_dns
  lb_internal              = var.lb_internal
  lb_type                  = var.lb_type

  # GraphDB Configurations

  graphdb_admin_password  = var.graphdb_admin_password
  graphdb_cluster_token   = var.graphdb_cluster_token
  graphdb_properties_path = var.graphdb_properties_path
  graphdb_java_options    = var.graphdb_java_options
  graphdb_license_path    = var.graphdb_license_path

  # VMs

  ec2_jvm_memory_ratio       = var.ec2_jvm_memory_ratio
  ec2_instance_type          = var.ec2_instance_type
  graphdb_node_count         = var.graphdb_node_count
  ec2_key_name               = var.ec2_key_name
  enable_detailed_monitoring = var.monitoring_enable_detailed_instance_monitoring
  root_ebs_volume_size       = var.root_ebs_volume_size

  # Backup Configurations

  deploy_backup          = var.deploy_backup
  backup_schedule        = var.backup_schedule
  backup_retention_count = var.backup_retention_count
  backup_bucket_name     = var.deploy_backup ? module.backup[0].bucket_name : ""

  # VM Image

  ami_id            = var.ami_id
  graphdb_version   = var.graphdb_version
  override_owner_id = var.override_owner_id

  # Managed Disks

  device_name             = var.device_name
  ebs_volume_type         = var.ebs_volume_type
  ebs_volume_size         = var.ebs_volume_size
  ebs_volume_iops         = var.ebs_volume_iops
  ebs_volume_throughput   = var.ebs_volume_throughput
  ebs_default_kms_key_arn = var.ebs_default_kms_key
  ebs_external_kms_key    = var.ebs_external_kms_key

  # EBS Encryption with KMS

  create_ebs_kms_key              = var.create_ebs_kms_key
  ebs_cmk_description             = var.ebs_cmk_description
  ebs_key_spec                    = var.ebs_key_spec
  ebs_key_enabled                 = var.ebs_key_enabled
  ebs_key_rotation_enabled        = var.ebs_key_rotation_enabled
  ebs_key_tags                    = var.ebs_key_tags
  ebs_key_deletion_window_in_days = var.ebs_key_deletion_window_in_days
  ebs_key_arn                     = local.calculated_ebs_kms_key_arn

  ebs_key_admin_arn   = local.ebs_key_admin_arn_joined
  ebs_cmk_alias       = var.ebs_cmk_alias
  ebs_default_kms_key = var.default_ebs_cmk_alias

  # DNS

  route53_zone_dns_name    = var.graphdb_node_count > 1 ? var.route53_zone_dns_name : null
  route53_existing_zone_id = var.route53_existing_zone_id

  # User Data Scripts

  deploy_monitoring         = var.deploy_monitoring
  external_address_protocol = local.calculated_protocol

  # S3 Replication Logging bucket Policy

  graphdb_logging_bucket_name             = var.deploy_logging_module ? module.logging[0].graphdb_logging_bucket_name : ""
  graphdb_logging_replication_bucket_name = var.deploy_logging_module && var.logging_enable_bucket_replication ? (module.logging_replication[0].graphdb_logging_bucket_name) : ""

  # Variables for Backup Bucket IAM Policy

  graphdb_backup_bucket_name             = var.deploy_backup ? module.backup[0].bucket_name : ""
  graphdb_backup_replication_bucket_name = var.deploy_backup && var.backup_enable_bucket_replication ? (module.backup_replication[0].graphdb_backup_replication_bucket_name) : ""

  # Variables for Logging Bucket IAM Policy

  logging_enable_replication = var.logging_enable_bucket_replication
  backup_enable_replication  = var.backup_enable_bucket_replication

  # ASG Instance deployment options

  graphdb_enable_userdata_scripts_on_reboot = var.graphdb_enable_userdata_scripts_on_reboot
  user_supplied_scripts                     = var.graphdb_user_supplied_scripts
  user_supplied_templates                   = var.graphdb_user_supplied_templates
  user_supplied_rendered_templates          = var.graphdb_user_supplied_rendered_templates
  enable_asg_wait                           = var.enable_asg_wait

  # Parameter Store Encryption

  create_parameter_store_kms_key              = var.create_parameter_store_kms_key
  parameter_store_cmk_alias                   = var.parameter_store_cmk_alias
  parameter_store_key_admin_arn               = local.parameter_store_key_admin_arn_joined
  parameter_store_cmk_description             = var.parameter_store_cmk_description
  parameter_store_key_spec                    = var.parameter_store_key_spec
  parameter_store_key_enabled                 = var.parameter_store_key_enabled
  parameter_store_key_rotation_enabled        = var.parameter_store_key_rotation_enabled
  parameter_store_key_tags                    = var.parameter_store_key_tags
  parameter_store_default_key                 = var.parameter_store_default_key
  parameter_store_key_deletion_window_in_days = var.parameter_store_key_deletion_window_in_days
  parameter_store_external_kms_key            = var.parameter_store_external_kms_key
  parameter_store_key_arn                     = local.calculated_parameter_store_kms_key_arn
}

module "external_dns" {
  source = "./modules/external_dns_records"

  count = local.deploy_external_dns_records

  zone_name        = var.external_dns_records_zone_name
  private_zone     = var.external_dns_records_private_zone
  vpc_associations = var.external_dns_records_private_zone ? var.external_dns_records_vpc_associations : []
  vpc_id           = var.external_dns_records_vpc_id
  vpc_region       = var.external_dns_records_vpc_region
  existing_zone_id = var.external_dns_records_existing_zone_id
  force_destroy    = var.external_dns_records_force_destroy
  allow_overwrite  = var.external_dns_records_allow_overwrite

  a_records_list     = local.aws_a_records_effective
  cname_records_list = local.aws_cname_records_effective
}
