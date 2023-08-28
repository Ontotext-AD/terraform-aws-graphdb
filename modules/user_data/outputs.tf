output "graphdb_userdata_base64_encoded" {
  value = base64encode(local.graphdb_user_data)
}
