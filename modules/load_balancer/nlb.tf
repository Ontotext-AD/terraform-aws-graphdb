resource "aws_lb" "graphdb_nlb" {
  count = local.is_nlb ? 1 : 0

  name                       = local.lb_name
  internal                   = var.lb_internal
  load_balancer_type         = "network"
  subnets                    = var.lb_subnets
  enable_deletion_protection = var.lb_enable_deletion_protection
  security_groups            = var.lb_security_groups

  dynamic "access_logs" {
    for_each = var.lb_enable_access_logs ? [1] : []

    content {
      bucket  = var.lb_access_logs_bucket_name
      enabled = true
    }
  }
}

resource "aws_lb_target_group" "graphdb_nlb_tg" {
  count = local.is_nlb ? 1 : 0

  name                 = local.target_group_name
  port                 = var.graphdb_node_count > 1 ? 7200 : 7201
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = var.lb_deregistration_delay

  health_check {
    protocol            = "TCP"
    port                = var.graphdb_node_count > 1 ? 7200 : 7201
    interval            = var.lb_health_check_interval
    healthy_threshold   = var.lb_healthy_threshold
    unhealthy_threshold = var.lb_unhealthy_threshold
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "graphdb_nlb_tcp" {
  count             = local.is_nlb && !var.lb_tls_enabled ? 1 : 0
  load_balancer_arn = aws_lb.graphdb_nlb[0].arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.graphdb_nlb_tg[0].arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "graphdb_nlb_tls" {
  count = local.is_nlb && var.lb_tls_enabled ? 1 : 0

  load_balancer_arn = aws_lb.graphdb_nlb[0].arn
  port              = 443
  protocol          = "TLS"
  certificate_arn   = var.lb_tls_certificate_arn
  ssl_policy        = var.lb_tls_policy

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.graphdb_nlb_tg[0].arn
  }

  lifecycle {
    create_before_destroy = true
  }
}
