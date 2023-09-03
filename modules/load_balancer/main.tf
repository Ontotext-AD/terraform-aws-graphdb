locals {
  lb_protocol = "TCP"
  lb_name     = "${var.resource_name_prefix}-graphdb"
}

resource "aws_lb" "graphdb" {
  name                       = local.lb_name
  internal                   = var.lb_internal
  load_balancer_type         = "network"
  subnets                    = var.lb_subnets
  enable_deletion_protection = var.lb_enable_deletion_protection
}

resource "aws_lb_target_group" "graphdb" {
  name   = local.lb_name
  vpc_id = var.vpc_id

  target_type          = "instance"
  port                 = 7200
  protocol             = local.lb_protocol
  deregistration_delay = var.lb_deregistration_delay

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    protocol            = "HTTP"
    port                = 7201
    path                = var.lb_health_check_path
    interval            = var.lb_health_check_interval
  }
}

resource "aws_lb_listener" "graphdb" {
  load_balancer_arn = aws_lb.graphdb.id
  port              = 80
  protocol          = local.lb_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.graphdb.arn
  }
}
