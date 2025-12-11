
locals {
  # KMS Key ARNs
  calculated_parameter_store_kms_key_arn = var.create_parameter_store_kms_key ? (
    var.parameter_store_external_kms_key != "" ? var.parameter_store_external_kms_key :
    module.graphdb.parameter_store_cmk_arn != "" ? module.graphdb.parameter_store_cmk_arn :
    var.parameter_store_default_key
  ) : var.parameter_store_default_key

  calculated_ebs_kms_key_arn = var.create_ebs_kms_key ? (
    var.ebs_external_kms_key != "" ? var.ebs_external_kms_key :
    module.graphdb.ebs_kms_key_arn != "" ? module.graphdb.ebs_kms_key_arn :
    var.ebs_default_kms_key
  ) : var.ebs_default_kms_key

  calculated_s3_kms_key_arn = var.create_s3_kms_key ? (
    var.s3_external_kms_key_arn != "" ? var.s3_external_kms_key_arn :
    module.backup[0].s3_cmk_arn != "" ? module.backup[0].s3_cmk_arn :
    var.s3_kms_default_key
  ) : var.s3_kms_default_key

  calculated_sns_kms_key_arn = var.create_sns_kms_key ? (
    var.sns_external_kms_key != "" ? var.sns_external_kms_key :
    module.monitoring[0].sns_cmk_arn != "" ? module.monitoring[0].sns_cmk_arn :
    var.sns_default_kms_key
  ) : var.sns_default_kms_key

  cmk_key_alias = var.deploy_monitoring ? (
    var.app_name != "" && var.environment_name != ""
    ? "alias/${var.app_name}-${var.environment_name}-graphdb-sns-cmk-alias"
    : var.sns_cmk_key_alias
  ) : null

  cmk_availability_key_alias = var.deploy_monitoring ? (
    var.app_name != "" && var.environment_name != ""
    ? "alias/${var.app_name}-${var.environment_name}-graphdb-availability-sns-cmk-alias"
    : var.cmk_availability_key_alias
  ) : null

  # TLS & Protocol
  lb_tls_enabled      = var.lb_tls_certificate_arn != "" ? true : false
  calculated_protocol = local.lb_tls_enabled ? "https" : "http"

  # Subnet CIDR lists
  effective_private_subnet_cidrs = (
    var.lb_type == "application"
    ? var.vpc_private_subnet_cidrs
    : (var.graphdb_node_count == 1 ? [var.vpc_private_subnet_cidrs[0]] : var.vpc_private_subnet_cidrs)
  )

  effective_public_subnet_cidrs = (
    var.lb_type == "application"
    ? var.vpc_public_subnet_cidrs
    : (var.graphdb_node_count == 1 ? [var.vpc_public_subnet_cidrs[0]] : var.vpc_public_subnet_cidrs)
  )

  all_private_subnet_ids = var.vpc_id == "" ? module.vpc[0].private_subnet_ids : var.vpc_private_subnet_ids
  all_public_subnet_ids  = var.vpc_id == "" ? module.vpc[0].public_subnet_ids : var.vpc_public_subnet_ids

  lb_subnets = var.existing_lb_arn != "" ? var.existing_lb_subnets : (
    var.lb_type == "application" ? (
      var.lb_internal
      ? slice(
        local.all_private_subnet_ids,
        0,
        min(2, length(local.all_private_subnet_ids))
      )
      : slice(
        local.all_public_subnet_ids,
        0,
        min(2, length(local.all_public_subnet_ids))
      )
      ) : (
      var.graphdb_node_count == 1 ? [
        (
          var.lb_internal
          ? local.all_private_subnet_ids[0]
          : local.all_public_subnet_ids[0]
        )
        ] : (
        var.lb_internal
        ? local.all_private_subnet_ids
        : local.all_public_subnet_ids
      )
    )
  )

  graphdb_subnets = var.graphdb_node_count == 1 ? [local.all_private_subnet_ids[0]] : local.all_private_subnet_ids

  # Load Balancer ARNs & DNS
  lb_arn_list = var.existing_lb_arn != "" ? [var.existing_lb_arn] : module.load_balancer[*].lb_arn

  lb_tg_arn_list = (
    var.existing_lb_target_group_arns != null &&
    length(var.existing_lb_target_group_arns) > 0
  ) ? var.existing_lb_target_group_arns : module.load_balancer[*].lb_target_group_arn

  lb_dns = var.existing_lb_dns_name != "" ? var.existing_lb_dns_name : (
    var.graphdb_external_dns != "" ? var.graphdb_external_dns :
    try(module.load_balancer[0].lb_dns_name, "")
  )

  # Admin ARNs from IAM roles (preferred - AWS best practice)
  admin_role_arns = var.iam_admin_role_arns != null ? var.iam_admin_role_arns : []

  # Admin ARNs from IAM group (legacy fallback)
  admin_user_arns = var.iam_admin_group != "" && length(data.aws_iam_group.iam_admin_group[0].users) > 0 ? [
  for user in data.aws_iam_group.iam_admin_group[0].users : user.arn] : []

  # Combined admin ARNs: roles take precedence, but users from group can be combined
  # If roles are provided, use them (optionally combined with users for backward compatibility)
  # Otherwise, fall back to users from group, then individual key admin ARN variables
  combined_admin_arns = length(local.admin_role_arns) > 0 ? (
    length(local.admin_user_arns) > 0 ? concat(local.admin_role_arns, local.admin_user_arns) : local.admin_role_arns
    ) : (
    length(local.admin_user_arns) > 0 ? local.admin_user_arns : []
  )

  # Key Admin Logic
  # Priority: 1) Combined roles+users, 2) Individual key admin ARN variables (filtering empty strings)
  ebs_key_admin_arn = (
    length(local.combined_admin_arns) > 0
    ? local.combined_admin_arns
    : trimspace(var.ebs_key_admin_arn) != ""
    ? (can(tolist(var.ebs_key_admin_arn)) ? tolist(var.ebs_key_admin_arn) : [var.ebs_key_admin_arn])
    : []
  )

  s3_key_admin_arn = (
    length(local.combined_admin_arns) > 0
    ? local.combined_admin_arns
    : trimspace(var.s3_kms_key_admin_arn) != ""
    ? (can(tolist(var.s3_kms_key_admin_arn)) ? tolist(var.s3_kms_key_admin_arn) : [var.s3_kms_key_admin_arn])
    : []
  )

  sns_key_admin_arn = (
    length(local.combined_admin_arns) > 0
    ? local.combined_admin_arns
    : trimspace(var.sns_key_admin_arn) != ""
    ? (can(tolist(var.sns_key_admin_arn)) ? tolist(var.sns_key_admin_arn) : [var.sns_key_admin_arn])
    : []
  )

  parameter_store_key_admin_arn = (
    length(local.combined_admin_arns) > 0
    ? local.combined_admin_arns
    : trimspace(var.parameter_store_key_admin_arn) != ""
    ? (can(tolist(var.parameter_store_key_admin_arn)) ? tolist(var.parameter_store_key_admin_arn) : [var.parameter_store_key_admin_arn])
    : []
  )

  # Comma-joined ARNs for modules expecting string input
  ebs_key_admin_arn_joined             = join(",", local.ebs_key_admin_arn)
  s3_key_admin_arn_joined              = join(",", local.s3_key_admin_arn)
  sns_key_admin_arn_joined             = join(",", local.sns_key_admin_arn)
  parameter_store_key_admin_arn_joined = join(",", local.parameter_store_key_admin_arn)

  deploy_external_dns_records = var.external_dns_records_zone_name != null && trimspace(var.external_dns_records_zone_name) != "" ? 1 : 0

  aws_rec_name    = trimspace(var.external_dns_records_name) == "" ? "@" : var.external_dns_records_name
  aws_cname_label = local.aws_rec_name == "@" ? "www" : "www.${local.aws_rec_name}"

  alb_dns_name = coalesce(try(module.load_balancer[0].lb_dns_name, null), var.external_dns_records_alb_dns_name_override)
  alb_zone_id  = coalesce(try(module.load_balancer[0].lb_zone_id, null), var.external_dns_records_alb_zone_id_override)

  has_alb = var.existing_lb_arn != "" || length(module.load_balancer) > 0

  aws_cname_user = coalesce(var.external_dns_records_cname_records_list, [])

  aws_apex_fqdn = local.aws_rec_name == "@" ? var.external_dns_records_zone_name : "${local.aws_rec_name}.${var.external_dns_records_zone_name}"

  aws_a_user_normalized = [
    for r in coalesce(var.external_dns_records_a_records_list, []) : {
      name    = r.name
      type    = try(r.type, "A")
      ttl     = try(r.ttl, null)
      records = try(r.records, null)
      alias   = try(r.alias, null)
    }
  ]

  aws_a_alias_synth = local.has_alb ? [
    {
      name    = local.aws_rec_name
      type    = "A"
      ttl     = null
      records = null
      alias = {
        name                   = local.alb_dns_name
        zone_id                = local.alb_zone_id
        evaluate_target_health = false
      }
    }
  ] : []

  aws_a_records_effective = length(local.aws_a_user_normalized) > 0 ? local.aws_a_user_normalized : local.aws_a_alias_synth

  aws_cname_records_effective = (
    length(local.aws_cname_user) > 0 ? local.aws_cname_user :
    (local.has_alb ? [{
      name   = local.aws_cname_label
      ttl    = var.external_dns_records_ttl
      record = local.aws_apex_fqdn
    }] : [])
  )
}
