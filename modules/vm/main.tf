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

resource "aws_security_group" "graphdb" {
  name        = "${var.resource_name_prefix}-graphdb"
  description = "Security group for GraphDB components"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "graphdb_network_lb_ingress" {
  count = var.allowed_inbound_cidrs != null ? 1 : 0

  description       = "CIRDs allowed to access GraphDB."
  security_group_id = aws_security_group.graphdb.id
  type              = "ingress"
  from_port         = 7200
  to_port           = 7200
  protocol          = "tcp"
  cidr_blocks       = var.allowed_inbound_cidrs
}

resource "aws_security_group_rule" "graphdb_lb_healthchecks" {
  description       = "Allow the load balancer to healthcheck the GraphDB nodes and access the proxies."
  security_group_id = aws_security_group.graphdb.id
  type              = "ingress"
  from_port         = 7200
  to_port           = 7201
  protocol          = "tcp"
  cidr_blocks       = local.lb_subnet_cidr_blocks
}

resource "aws_security_group_rule" "graphdb_internal_http" {
  description       = "Allow GraphDB proxies and nodes to communicate (HTTP)."
  security_group_id = aws_security_group.graphdb.id
  type              = "ingress"
  from_port         = 7200
  to_port           = 7201
  protocol          = "tcp"
  cidr_blocks       = local.subnet_cidr_blocks
}

resource "aws_security_group_rule" "graphdb_internal_raft" {
  description       = "Allow GraphDB proxies and nodes to communicate (Raft)."
  security_group_id = aws_security_group.graphdb.id
  type              = "ingress"
  from_port         = 7300
  to_port           = 7301
  protocol          = "tcp"
  cidr_blocks       = local.subnet_cidr_blocks
}

resource "aws_security_group_rule" "graphdb_ssh_inbound" {
  count             = var.allowed_inbound_cidrs_ssh != null ? 1 : 0
  description       = "Allow specified CIDRs SSH access to the GraphDB instances."
  security_group_id = aws_security_group.graphdb.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_inbound_cidrs_ssh
}

resource "aws_security_group_rule" "graphdb_outbound" {
  description       = "Allow GraphDB nodes to send outbound traffic"
  security_group_id = aws_security_group.graphdb.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_launch_template" "graphdb" {
  name          = "${var.resource_name_prefix}-graphdb"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name != null ? var.key_name : null
  user_data     = var.userdata_script
  vpc_security_group_ids = [
    aws_security_group.graphdb.id,
  ]

  ebs_optimized = "true"

  iam_instance_profile {
    name = var.aws_iam_instance_profile
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

resource "aws_autoscaling_group" "graphdb" {
  name                = "${var.resource_name_prefix}-graphdb"
  min_size            = var.node_count
  max_size            = var.node_count
  desired_capacity    = var.node_count
  vpc_zone_identifier = var.graphdb_subnets

  target_group_arns = var.graphdb_target_group_arns

  launch_template {
    id      = aws_launch_template.graphdb.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(var.common_tags, {
      "Name"                                = "${var.resource_name_prefix}-graphdb-node"
      "${var.resource_name_prefix}-graphdb" = "node"
    })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
