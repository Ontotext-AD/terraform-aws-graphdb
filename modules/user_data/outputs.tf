output "graphdb_userdata_base64_encoded" {
  value = base64encode(local.graphdb_user_data)
}

output "graphdb_max_memory" {
  value = local.jvm_max_memory
}
