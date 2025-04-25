locals {
  is_alb = var.lb_type == "application"
  is_nlb = var.lb_type == "network"

  lb_name           = var.resource_name_prefix
  target_group_name = "${var.resource_name_prefix}-tg-${random_id.tg_name_suffix.hex}"
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
