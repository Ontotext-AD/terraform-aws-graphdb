# GraphDB AWS Terraform Module Changelog

## 1.0.0
Updated the user data scripts to allow setup of multi node cluster based on the `node_count` variable.
Added ability for a node to rejoin the cluster if raft folder is empty or missing.
Added stable network names based on AZ deployment.

## 0.1.0

Initial version for GraphDB AWS module
