resource "random_password" "graphdb_admin_password" {
  count  = var.graphdb_admin_password != null ? 0 : 1
  length = 8
}

resource "random_password" "graphdb_cluster_token" {
  count   = var.graphdb_cluster_token != null ? 0 : 1
  length  = 16
  special = true
}

locals {
  graphdb_cluster_token  = var.graphdb_cluster_token != null ? var.graphdb_cluster_token : random_password.graphdb_cluster_token[0].result
  graphdb_admin_password = var.graphdb_admin_password != null ? var.graphdb_admin_password : random_password.graphdb_admin_password[0].result
}