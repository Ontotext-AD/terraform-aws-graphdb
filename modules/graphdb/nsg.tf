locals {
  calculated_graphdb_port = var.graphdb_node_count == 1 ? 7201 : 7200
}

resource "aws_security_group" "graphdb_security_group" {
  name        = var.resource_name_prefix
  description = "Security group for GraphDB components"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "graphdb_internal_http" {
  description       = "Allow GraphDB proxies and nodes to communicate (HTTP)."
  security_group_id = aws_security_group.graphdb_security_group.id
  type              = "ingress"
  from_port         = local.calculated_graphdb_port
  to_port           = 7201
  protocol          = "tcp"
  cidr_blocks       = local.subnet_cidr_blocks
}

resource "aws_security_group_rule" "graphdb_internal_raft" {
  count = var.graphdb_node_count > 1 ? 1 : 0

  description       = "Allow GraphDB proxies and nodes to communicate (Raft)."
  security_group_id = aws_security_group.graphdb_security_group.id
  type              = "ingress"
  from_port         = 7300
  to_port           = 7301
  protocol          = "tcp"
  cidr_blocks       = local.subnet_cidr_blocks
}

resource "aws_security_group_rule" "graphdb_ssh_inbound" {
  count = var.allowed_inbound_cidrs_ssh != null ? 1 : 0

  description       = "Allow specified CIDRs SSH access to the GraphDB instances."
  security_group_id = aws_security_group.graphdb_security_group.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_inbound_cidrs_ssh
}

resource "aws_security_group_rule" "graphdb_outbound" {
  description       = "Allow GraphDB nodes to send outbound traffic"
  security_group_id = aws_security_group.graphdb_security_group.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "graphdb_network_lb_ingress" {
  count = var.allowed_inbound_cidrs != null ? 1 : 0

  description       = "CIRDs allowed to access GraphDB."
  security_group_id = aws_security_group.graphdb_security_group.id
  type              = "ingress"
  from_port         = local.calculated_graphdb_port
  to_port           = local.calculated_graphdb_port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_inbound_cidrs
}

resource "aws_security_group_rule" "graphdb_lb_healthchecks" {
  # Since it creates duplicated rule if lb_internal is true we need to have a toggle to enable/disable this rule based on the type of the access to the LB
  count = var.lb_enable_private_access ? 0 : 1

  description       = "Allow the load balancer to healthcheck the GraphDB nodes and access the proxies."
  security_group_id = aws_security_group.graphdb_security_group.id
  type              = "ingress"
  from_port         = local.calculated_graphdb_port
  to_port           = 7201
  protocol          = "tcp"
  cidr_blocks       = local.lb_subnet_cidr_blocks
}
