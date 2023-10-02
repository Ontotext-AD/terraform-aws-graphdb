locals {
  graphdb_user_data = templatefile(
    var.user_supplied_userdata_path != null ? var.user_supplied_userdata_path : "${path.module}/templates/install_graphdb.sh.tpl",
    {
      region                 = var.aws_region
      name                   = var.resource_name_prefix
      device_name            = var.device_name
      backup_schedule        = var.backup_schedule
      backup_iam_key_id      = var.backup_iam_key_id
      backup_iam_key_secret  = var.backup_iam_key_secret
      backup_retention_count = var.backup_retention_count

      ebs_volume_type       = var.ebs_volume_type
      ebs_volume_size       = var.ebs_volume_size
      ebs_volume_iops       = var.ebs_volume_iops
      ebs_volume_throughput = var.ebs_volume_throughput
      ebs_kms_key_arn       = var.ebs_kms_key_arn

      zone_dns_name = var.zone_dns_name
      zone_id       = var.zone_id
    }
  )
}
