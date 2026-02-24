data "cloudinit_config" "graphdb_user_data" {
  base64_encode = true
  gzip          = true

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
        #!/bin/bash
        set -euo pipefail

        until ping -c 1 google.com &> /dev/null; do
          echo "waiting for outbound connectivity"
          sleep 5
        done

        # Stop GraphDB to override configurations
        echo "Stopping GraphDB"
        systemctl stop graphdb
      EOF
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/00_functions.sh", {
      name : var.resource_name_prefix
      enable_asg_wait = var.enable_asg_wait
      m2m_enabled : var.m2m_app_registration_client_secret != null && var.m2m_app_registration_client_secret != "" ? "true" : "false"
      m2m_client_id : var.m2m_app_registration_client_id != null ? var.m2m_app_registration_client_id : ""
      m2m_scope : var.m2m_scope != null ? var.m2m_scope : ""
      openid_tenant_id : var.openid_tenant_id != null ? var.openid_tenant_id : ""
      region : var.aws_region
    })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/01_wait_node_count.sh.tpl", {
      name : var.resource_name_prefix
      node_count : var.graphdb_node_count
      enable_asg_wait : var.enable_asg_wait
    })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/02_disk_management.sh.tpl", {
      name : var.resource_name_prefix
      ebs_volume_type : var.ebs_volume_type
      ebs_volume_size : var.ebs_volume_size
      ebs_volume_iops : var.ebs_volume_iops
      ebs_volume_throughput : var.ebs_volume_throughput
      deployment_tag : var.deployment_restriction_tag
      device_name : var.device_name
      ebs_kms_key_arn : var.ebs_key_arn
    })
  }

  dynamic "part" {
    for_each = var.graphdb_node_count > 1 ? [1] : []

    content {
      content_type = "text/x-shellscript"
      content = templatefile("${path.module}/templates/03_dns_provisioning.sh.tpl", {
        route53_zone_id : var.route53_existing_zone_id != "" ? var.route53_existing_zone_id : aws_route53_zone.graphdb_zone[0].id
        route53_zone_dns_name : var.route53_zone_dns_name
        name : var.resource_name_prefix
        region : var.aws_region
      })
    }
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/04_gdb_conf_overrides.sh.tpl", {
      name : var.resource_name_prefix
      region : var.aws_region
      external_address_protocol : var.external_address_protocol
      graphdb_lb_dns_name : var.graphdb_lb_dns_name
      lb_context_path : var.lb_context_path
      JVM_MEMORY_RATIO : var.ec2_jvm_memory_ratio
      m2m_enabled : var.m2m_app_registration_client_secret != null && var.m2m_app_registration_client_secret != "" ? "true" : "false"
      openid_issuer : var.openid_issuer != null ? var.openid_issuer : ""
      openid_client_id : var.openid_client_id != null ? var.openid_client_id : ""
      openid_username_claim : var.openid_username_claim
      openid_auth_flow : var.openid_auth_flow
      openid_token_type : var.openid_token_type
      openid_auth_methods : var.openid_auth_methods != null ? var.openid_auth_methods : ""
      openid_auth_database : var.openid_auth_database != null ? var.openid_auth_database : ""
      oauth_roles_claim : var.oauth_roles_claim
      oauth_roles_prefix : var.oauth_roles_prefix
    })
  }

  dynamic "part" {
    for_each = var.deploy_backup ? [1] : []

    content {
      content_type = "text/x-shellscript"
      content = templatefile("${path.module}/templates/05_gdb_backup_conf.sh.tpl", {
        name : var.resource_name_prefix
        region : var.aws_region
        backup_schedule : var.backup_schedule
        backup_retention_count : var.backup_retention_count
        backup_bucket_name : var.backup_bucket_name
        deploy_backup : var.deploy_backup
        m2m_enabled : var.m2m_app_registration_client_secret != null && var.m2m_app_registration_client_secret != "" ? "true" : "false"
        m2m_client_id : var.m2m_app_registration_client_id != null ? var.m2m_app_registration_client_id : ""
        m2m_scope : var.m2m_scope != null ? var.m2m_scope : ""
        openid_tenant_id : var.openid_tenant_id != null ? var.openid_tenant_id : ""
      })
    }
  }

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/templates/06_linux_overrides.sh.tpl", {})
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/07_cloudwatch_setup.sh.tpl", {
      name : var.resource_name_prefix
      deploy_monitoring : var.deploy_monitoring
      region : var.aws_region
    })
  }

  dynamic "part" {
    for_each = var.graphdb_node_count > 1 ? [1] : []

    content {
      content_type = "text/x-shellscript"
      content = templatefile("${path.module}/templates/08_cluster_setup.sh.tpl", {
        name : var.resource_name_prefix
        region : var.aws_region
        route53_zone_id : var.route53_existing_zone_id != "" ? var.route53_existing_zone_id : aws_route53_zone.graphdb_zone[0].id
        route53_zone_dns_name : var.route53_zone_dns_name
      })
    }
  }

  dynamic "part" {
    for_each = var.graphdb_node_count > 1 ? [1] : []

    content {
      content_type = "text/x-shellscript"
      content = templatefile("${path.module}/templates/09_node_join.sh.tpl", {
        region : var.aws_region
        name : var.resource_name_prefix
        node_count : var.graphdb_node_count
        route53_zone_id : var.route53_existing_zone_id != "" ? var.route53_existing_zone_id : aws_route53_zone.graphdb_zone[0].id
        route53_zone_dns_name : var.route53_zone_dns_name
      })
    }
  }

  # 10 Start GDB services - Single node
  dynamic "part" {
    for_each = var.graphdb_node_count == 1 ? [1] : []
    content {
      content_type = "text/x-shellscript"
      content = templatefile("${path.module}/templates/10_start_single_graphdb_services.sh.tpl", {
        name : var.resource_name_prefix
        region : var.aws_region
        zone_id = var.route53_existing_zone_id != "" ? var.route53_existing_zone_id : (var.graphdb_node_count > 1 ? aws_route53_zone.graphdb_zone[0].id : "")
        route53_zone_dns_name : var.graphdb_node_count > 1 ? var.route53_zone_dns_name : ""
      })
    }
  }

  # 11 Execute additional scripts
  dynamic "part" {
    for_each = var.graphdb_enable_userdata_scripts_on_reboot ? [1] : []
    content {
      content_type = "text/cloud-config"
      filename     = "cloud-config.txt"
      content      = <<-EOF
      #cloud-config
      cloud_final_modules:
        - [scripts-user, always]
    EOF
    }
  }

  # 12 Make aws-cli accessible only for root user iff backup is not enabled (otherwise, will be owned by the backup user)
  dynamic "part" {
    for_each = var.deploy_backup ? [] : [1]

    content {
      content_type = "text/x-shellscript"
      content      = <<-EOF
      #!/bin/bash
      set -euo pipefail
      chmod -R og-rwx /usr/local/aws-cli/
    EOF
    }
  }

  # Execute additional scripts
  dynamic "part" {
    for_each = var.user_supplied_scripts
    content {
      content_type = "text/x-shellscript"
      content      = file(part.value)
    }
  }

  # Execute additional rendered templates
  dynamic "part" {
    for_each = var.user_supplied_rendered_templates
    content {
      content_type = "text/x-shellscript"
      content      = part.value
    }
  }

  # Execute additional templates
  dynamic "part" {
    for_each = var.user_supplied_templates
    content {
      content_type = "text/x-shellscript"
      content      = templatefile(part.value["path"], part.value["variables"])
    }
  }
}
