resource "aws_security_group" "alb" {
  count = local.is_alb ? 1 : 0

  name        = "${var.resource_name_prefix}-alb-sg"
  description = "Allow inbound HTTP/HTTPS to GraphDB ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_inbound_cidrs_lb
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_inbound_cidrs_lb
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "graphdb_alb" {
  count = local.is_alb ? 1 : 0

  name                       = local.lb_name
  internal                   = var.lb_internal
  load_balancer_type         = "application"
  subnets                    = var.lb_subnets
  enable_deletion_protection = var.lb_enable_deletion_protection
  security_groups            = concat([aws_security_group.alb[0].id], var.lb_security_groups)
  idle_timeout               = var.lb_idle_timeout
  client_keep_alive          = var.lb_client_keep_alive_timeout
  enable_http2               = var.lb_enable_http2

  dynamic "access_logs" {
    for_each = var.lb_enable_access_logs ? [1] : []

    content {
      bucket  = var.lb_access_logs_bucket_name
      enabled = true
    }
  }
}

resource "aws_lb_target_group" "graphdb_alb_tg" {
  count = local.is_alb ? 1 : 0

  name                 = local.target_group_name
  port                 = var.graphdb_node_count > 1 ? 7200 : 7201
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = var.lb_deregistration_delay

  health_check {
    protocol            = "HTTP"
    port                = var.graphdb_node_count > 1 ? 7200 : 7201
    interval            = var.lb_health_check_interval
    healthy_threshold   = var.lb_healthy_threshold
    unhealthy_threshold = var.lb_unhealthy_threshold
    # Prepend context path only if configured
    path = var.lb_context_path != "" ? "${var.lb_context_path}${var.lb_health_check_path}" : (var.graphdb_node_count > 1 ? var.lb_health_check_path : "/protocol")
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "graphdb_alb_http" {
  count = local.is_alb ? 1 : 0

  load_balancer_arn = aws_lb.graphdb_alb[0].arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.lb_tls_enabled ? ["redirect"] : (var.lb_context_path != "" ? ["fixed-response"] : ["forward"])

    content {
      type = default_action.value == "redirect" ? "redirect" : (default_action.value == "fixed-response" ? "fixed-response" : "forward")

      dynamic "redirect" {
        for_each = default_action.value == "redirect" ? [1] : []
        content {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
          host        = "#{host}"
          path        = "/#{path}"
          query       = "#{query}"
        }
      }

      dynamic "fixed_response" {
        for_each = default_action.value == "fixed-response" ? [1] : []
        content {
          content_type = "text/plain"
          message_body = "Not Found"
          status_code  = "404"
        }
      }

      dynamic "forward" {
        for_each = default_action.value == "forward" ? [1] : []
        content {
          target_group {
            arn    = aws_lb_target_group.graphdb_alb_tg[0].arn
            weight = 1
          }
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" "graphdb_path_based_http" {
  count = local.is_alb && !var.lb_tls_enabled && var.lb_context_path != "" ? 1 : 0

  listener_arn = aws_lb_listener.graphdb_alb_http[0].arn
  priority     = 100

  dynamic "transform" {
    for_each = var.lb_enable_context_path_rewrite ? [1] : []
    content {
      type = "url-rewrite"

      url_rewrite {
        rewrites = [
          { regex = "^${var.lb_context_path}/(.*)$", replace = "/$1" },
          { regex = "^${var.lb_context_path}$",      replace = "/" }
        ]
      }
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.graphdb_alb_tg[0].arn
  }

  condition {
    path_pattern {
      values = ["${var.lb_context_path}/*", var.lb_context_path]
    }
  }
}

resource "aws_lb_listener" "graphdb_alb_https" {
  count = local.is_alb && var.lb_tls_enabled ? 1 : 0

  load_balancer_arn = aws_lb.graphdb_alb[0].arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.lb_tls_certificate_arn
  ssl_policy        = var.lb_tls_policy


  default_action {
    type = var.lb_context_path != "" ? "fixed-response" : "forward"

    dynamic "fixed_response" {
      for_each = var.lb_context_path != "" ? [1] : []
      content {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }
    }

    target_group_arn = var.lb_context_path == "" ? aws_lb_target_group.graphdb_alb_tg[0].arn : null
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" "graphdb_path_based_https" {
  count = local.is_alb && var.lb_tls_enabled && var.lb_context_path != "" ? 1 : 0

  listener_arn = aws_lb_listener.graphdb_alb_https[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.graphdb_alb_tg[0].arn
  }

  condition {
    path_pattern {
      values = ["${var.lb_context_path}/*", var.lb_context_path]
    }
  }
}

resource "aws_security_group" "graphdb" {
  count = local.is_alb ? 1 : 0

  name        = "${var.resource_name_prefix}-graphdb-sg"
  description = "Allow GraphDB traffic only from the ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow GraphDB port from ALB"
    from_port       = var.graphdb_node_count > 1 ? 7200 : 7201
    to_port         = var.graphdb_node_count > 1 ? 7200 : 7201
    protocol        = "tcp"
    security_groups = [aws_security_group.alb[0].id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
