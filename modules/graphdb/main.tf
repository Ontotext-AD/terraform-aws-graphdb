data "aws_ec2_instance_type" "graphdb" {
  count = var.ami_id != null ? 0 : 1

  instance_type = var.ec2_instance_type
}

data "aws_default_tags" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ami" "graphdb" {
  count = var.ami_id != null ? 0 : 1

  owners      = var.override_owner_id != null ? [var.override_owner_id] : ["679593333241"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ami-ontotext-graphdb-${var.graphdb_version}-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "architecture"
    values = data.aws_ec2_instance_type.graphdb[0].supported_architectures
  }
}

data "aws_subnet" "subnet" {
  count = length(var.graphdb_subnets)
  id    = var.graphdb_subnets[count.index]
}

data "aws_subnet" "lb_subnets" {
  count = length(var.lb_subnets)
  id    = var.lb_subnets[count.index]
}

locals {
  subnet_cidr_blocks    = [for s in data.aws_subnet.subnet : s.cidr_block]
  lb_subnet_cidr_blocks = [for s in data.aws_subnet.lb_subnets : s.cidr_block]
}

resource "aws_launch_template" "graphdb" {
  name          = var.resource_name_prefix
  image_id      = var.ami_id != null ? var.ami_id : data.aws_ami.graphdb[0].id
  instance_type = var.ec2_instance_type
  key_name      = var.ec2_key_name != null ? var.ec2_key_name : null
  user_data     = data.cloudinit_config.graphdb_user_data.rendered

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  vpc_security_group_ids = [
    aws_security_group.graphdb_security_group.id
  ]

  ebs_optimized = true

  iam_instance_profile {
    name = aws_iam_instance_profile.graphdb_iam_instance_profile.id
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  update_default_version = true
}

resource "aws_autoscaling_group" "graphdb_auto_scaling_group" {
  name                = var.resource_name_prefix
  min_size            = var.graphdb_node_count
  max_size            = var.graphdb_node_count
  desired_capacity    = var.graphdb_node_count
  vpc_zone_identifier = var.graphdb_subnets

  target_group_arns = var.graphdb_target_group_arns

  instance_maintenance_policy {
    min_healthy_percentage = var.instance_maintenance_policy_min_healthy_percentage
    max_healthy_percentage = var.instance_maintenance_policy_max_healthy_percentage
  }

  launch_template {
    id      = aws_launch_template.graphdb.id
    version = aws_launch_template.graphdb.latest_version
  }

  dynamic "instance_refresh" {
    for_each = var.asg_enable_instance_refresh ? [1] : []
    content {
      strategy = "Rolling"

      preferences {
        min_healthy_percentage = var.asg_instance_refresh_min_healthy_percentage
        instance_warmup        = var.asg_instance_refresh_instance_warmup
        skip_matching          = var.asg_instance_refresh_skip_matching
        checkpoint_delay       = var.asg_instance_refresh_checkpoint_delay
        checkpoint_percentages = [
          for i in range(var.graphdb_node_count) :
          floor((i + 1) * 100 / var.graphdb_node_count)
        ]
      }
    }
  }

  tag {
    key                 = "DeployTag"
    value               = var.deploy_tag
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = data.aws_default_tags.current.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

