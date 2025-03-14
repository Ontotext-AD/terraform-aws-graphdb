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
    })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/01_wait_node_count.sh.tpl", {
      name : var.resource_name_prefix
      node_count : var.graphdb_node_count
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
      deployment_tag : var.deploy_tag
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
    })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/05_gdb_backup_conf.sh.tpl", {
      name : var.resource_name_prefix
      region : var.aws_region
      backup_schedule : var.backup_schedule
      backup_retention_count : var.backup_retention_count
      backup_bucket_name : var.backup_bucket_name
      deploy_backup : var.deploy_backup
    })
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

  # 12 Make aws-cli accessible only for root user
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      set -euo pipefail
      chmod -R og-rwx /usr/local/aws-cli/
    EOF
  }
}
