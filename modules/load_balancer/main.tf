locals {
  is_alb = var.lb_type == "application"
  is_nlb = var.lb_type == "network"

  lb_flavor                   = local.is_alb ? "alb" : "nlb"
  lb_name                     = "${var.resource_name_prefix}-${local.lb_flavor}"
  target_group_name           = "${var.resource_name_prefix}-tg-${local.lb_flavor}-${random_id.tg_name_suffix.hex}"
  graphdb_backend_health_path = var.graphdb_node_count > 1 ? var.lb_health_check_path : "/protocol"
  lb_context_path_clean       = trim(var.lb_context_path, "/")
  lb_context_path_norm        = local.lb_context_path_clean != "" ? "/${local.lb_context_path_clean}" : ""
  lb_context_path_slash       = local.lb_context_path_clean != "" ? "/${local.lb_context_path_clean}/" : "/"

  effective_health_check_path = local.lb_context_path_clean != "" ? "${local.lb_context_path_norm}${local.graphdb_backend_health_path}" : local.graphdb_backend_health_path

  http_action_type = var.lb_tls_enabled ? "redirect" : (local.lb_context_path_clean != "" ? "fixed-response" : "forward")
}

# This creates a random suffix for the target group name
# it will only be regenerated if the graphdb_node_count changes.
# Required when recreating the target group when scaling from 1 to 3 or more nodes.

resource "random_id" "tg_name_suffix" {
  keepers = {
    node_count = var.graphdb_node_count
  }
  byte_length = 4
}
