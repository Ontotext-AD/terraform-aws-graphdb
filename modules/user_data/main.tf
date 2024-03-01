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
    content = templatefile("${path.module}/templates/01_disk_management.sh.tpl", {
      name : var.resource_name_prefix
      ebs_volume_type : var.ebs_volume_type
      ebs_volume_size : var.ebs_volume_size
      ebs_volume_iops : var.ebs_volume_iops
      ebs_volume_throughput : var.ebs_volume_throughput
      ebs_kms_key_arn : var.ebs_kms_key_arn
      device_name : var.device_name
    })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/02_dns_provisioning.sh.tpl", {
      zone_id : var.zone_id
      zone_dns_name : var.zone_dns_name
    })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/03_gdb_conf_overrides.sh.tpl", {
      name : var.resource_name_prefix
      region : var.aws_region
    })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/04_gdb_backup_conf.sh.tpl", {
      name : var.resource_name_prefix
      region : var.aws_region
      backup_schedule : var.backup_schedule
      backup_retention_count : var.backup_retention_count
      backup_bucket_name : var.backup_bucket_name
    })
  }

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/templates/05_linux_overrides.sh.tpl", {})
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/06_cloudwatch_setup.sh.tpl", {
      name : var.resource_name_prefix
      region : var.aws_region
    })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/07_cluster_setup.sh.tpl", {
      name : var.resource_name_prefix
      region : var.aws_region
      zone_id : var.zone_id
    })
  }
}
