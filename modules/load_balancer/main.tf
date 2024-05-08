locals {
  lb_name        = var.resource_name_prefix
  lb_tls_enabled = var.lb_tls_certificate_arn != null ? true : false
}

resource "aws_lb" "graphdb_lb" {
  name                       = local.lb_name
  internal                   = var.lb_internal
  load_balancer_type         = "network"
  subnets                    = var.lb_subnets
  enable_deletion_protection = var.lb_enable_deletion_protection
  security_groups            = var.lb_security_groups

  dynamic "access_logs" {
    for_each = var.lb_enable_access_logs ? ["enabled"] : []
    content {
      bucket  = var.lb_access_logs_bucket_name
      enabled = var.lb_enable_access_logs
    }
  }
}

resource "aws_lb_target_group" "graphdb_lb_target_group" {
  name   = local.lb_name
  vpc_id = var.vpc_id

  target_type          = "instance"
  port                 = 7200
  protocol             = "TCP"
  deregistration_delay = var.lb_deregistration_delay

  health_check {
    healthy_threshold   = var.lb_healthy_threshold
    unhealthy_threshold = var.lb_unhealthy_threshold
    protocol            = "HTTP"
    port                = 7201
    path                = var.lb_health_check_path
    interval            = var.lb_health_check_interval
  }
}

resource "aws_lb_listener" "graphdb_listener" {
  count = local.lb_tls_enabled ? 0 : 1

  load_balancer_arn = aws_lb.graphdb_lb.id
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.graphdb_lb_target_group.arn
  }
}

resource "aws_lb_listener" "graphdb_tls" {
  count = local.lb_tls_enabled ? 1 : 0

  load_balancer_arn = aws_lb.graphdb_lb.id
  port              = 443
  protocol          = "TLS"
  certificate_arn   = var.lb_tls_certificate_arn
  ssl_policy        = var.lb_tls_policy

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.graphdb_lb_target_group.arn
  }
}
