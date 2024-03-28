resource "aws_security_group" "graphdb" {
  name        = "${var.resource_name_prefix}-graphdb"
  description = "Security group for GraphDB components"
  vpc_id      = var.vpc_id
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