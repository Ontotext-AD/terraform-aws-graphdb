output "graphdb_userdata_base64_encoded" {
  description = "User data script for GraphDB VM scale set."
  value       = data.cloudinit_config.graphdb_user_data.rendered
}

