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
    path = local.lb_context_path_clean != "" ? "${local.lb_context_path_norm}${local.graphdb_backend_health_path}" : local.graphdb_backend_health_path
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -------------------------
# LISTENER: HTTP 80 (always default 404)
# -------------------------
resource "aws_lb_listener" "graphdb_alb_http" {
  count = local.is_alb ? 1 : 0

  load_balancer_arn = aws_lb.graphdb_alb[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# -------------------------
# RULE: HTTP -> HTTPS redirect (only when TLS enabled)
# Must be the top priority rule on HTTP listener
# -------------------------
resource "aws_lb_listener_rule" "http_to_https_redirect_all" {
  count = local.is_alb && var.lb_tls_enabled ? 1 : 0

  listener_arn = aws_lb_listener.graphdb_alb_http[0].arn
  priority     = 1

  action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
      host        = "#{host}"
      path        = local.lb_context_path_clean != "" ? "${local.lb_context_path_norm}#{path}" : "/#{path}"
      query       = "#{query}"
    }
  }

  condition {
    path_pattern { values = ["/*"] }
  }
}

# -------------------------
# RULE: HTTP forward-all when NO TLS and NO context path
# (otherwise, context-path rules handle forwarding)
# -------------------------
resource "aws_lb_listener_rule" "http_forward_all_no_context" {
  count = local.is_alb && !var.lb_tls_enabled && local.lb_context_path_clean == "" ? 1 : 0

  listener_arn = aws_lb_listener.graphdb_alb_http[0].arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.graphdb_alb_tg[0].arn
  }

  condition {
    path_pattern { values = ["/*"] }
  }
}

# -------------------------
# HTTP (no TLS) context path rule
# -------------------------
resource "aws_lb_listener_rule" "graphdb_path_based_http" {
  count = local.is_alb && !var.lb_tls_enabled && local.lb_context_path_clean != "" ? 1 : 0

  listener_arn = aws_lb_listener.graphdb_alb_http[0].arn
  priority     = 100

  transform {
    type = "url-rewrite"

    url_rewrite_config {
      rewrite {
        regex   = "^${local.lb_context_path_norm}(/(.*))?$"
        replace = "/$2"
      }
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.graphdb_alb_tg[0].arn
  }

  condition {
    path_pattern {
      values = [
        "${local.lb_context_path_norm}/*",
        local.lb_context_path_norm,
        "${local.lb_context_path_norm}/",
      ]
    }
  }
}

# -------------------------
# LISTENER: HTTPS 443 (always default 404)
# -------------------------
resource "aws_lb_listener" "graphdb_alb_https" {
  count = local.is_alb && var.lb_tls_enabled ? 1 : 0

  load_balancer_arn = aws_lb.graphdb_alb[0].arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.lb_tls_certificate_arn
  ssl_policy        = var.lb_tls_policy

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# -------------------------
# RULE: HTTPS forward-all when NO context path
# -------------------------
resource "aws_lb_listener_rule" "https_forward_all_no_context" {
  count = local.is_alb && var.lb_tls_enabled && local.lb_context_path_clean == "" ? 1 : 0

  listener_arn = aws_lb_listener.graphdb_alb_https[0].arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.graphdb_alb_tg[0].arn
  }

  condition {
    path_pattern { values = ["/*"] }
  }
}

# -------------------------
# HTTPS context path rule
# -------------------------
resource "aws_lb_listener_rule" "graphdb_path_based_https" {
  count = local.is_alb && var.lb_tls_enabled && local.lb_context_path_clean != "" ? 1 : 0

  listener_arn = aws_lb_listener.graphdb_alb_https[0].arn
  priority     = 100

  transform {
    type = "url-rewrite"

    url_rewrite_config {
      rewrite {
        regex   = "^${local.lb_context_path_norm}(/(.*))?$"
        replace = "/$2"
      }
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.graphdb_alb_tg[0].arn
  }

  condition {
    path_pattern {
      values = [
        "${local.lb_context_path_norm}/*",
        local.lb_context_path_norm,
        "${local.lb_context_path_norm}/",
      ]
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
