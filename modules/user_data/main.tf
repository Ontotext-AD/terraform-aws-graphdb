data "aws_ec2_instance_type" "graphdb" {
  instance_type = var.instance_type
}

locals {
  # MiB to GiB - 10
  jvm_max_memory = ceil(data.aws_ec2_instance_type.graphdb.memory_size * 0.0009765625 - 10)

  graphdb_user_data = templatefile(
    var.user_supplied_userdata_path != null ? var.user_supplied_userdata_path : "${path.module}/templates/start_graphdb.sh.tpl",
    {
      region      = var.aws_region
      name        = var.resource_name_prefix
      device_name = var.device_name

      backup_schedule        = var.backup_schedule
      backup_retention_count = var.backup_retention_count
      backup_bucket_name     = var.backup_bucket_name

      ebs_volume_type       = var.ebs_volume_type
      ebs_volume_size       = var.ebs_volume_size
      ebs_volume_iops       = var.ebs_volume_iops
      ebs_volume_throughput = var.ebs_volume_throughput
      ebs_kms_key_arn       = var.ebs_kms_key_arn

      zone_dns_name = var.zone_dns_name
      zone_id       = var.zone_id

      jvm_max_memory       = local.jvm_max_memory
      resource_name_prefix = var.resource_name_prefix
    }
  )
}
