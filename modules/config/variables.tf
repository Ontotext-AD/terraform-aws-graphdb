# REQUIRED parameters

variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.resource_name_prefix)) && !can(regex("^-", var.resource_name_prefix))
    error_message = "Resource name prefix cannot start with a hyphen and can only contain letters, numbers, and hyphens."
  }
}

# OPTIONAL parameters

variable "graphdb_admin_password" {
  description = "Password for the 'admin' user in GraphDB."
  type        = string
  sensitive   = true
}

variable "graphdb_cluster_token" {
  description = "Cluster token used for authenticating the communication between the nodes."
  sensitive   = true
}

variable "graphdb_license_path" {
  description = "Local path to a file, containing a GraphDB Enterprise license."
  type        = string
  default     = null
}

variable "graphdb_lb_dns_name" {
  description = "The DNS name of the load balancer for the GraphDB nodes."
  type        = string
  default     = ""
}

variable "graphdb_config" {
  description = "Path to the initial config to add for GraphDB."
  type        = string
  default     = "/home/kristian/Ontotext/terraform-aws-graphdb/modules/config/example_config" #to delete and 
}

variable "GDB_JAVA_OPTS" {
  description = "GDB_JAVA_OPTS Options to add for GraphDB configuration"
  type        = string
  default     = "test"  #Need to find what to put in default since it is required to have something
}