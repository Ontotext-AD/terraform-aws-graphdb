User Data Scripts
=================

This README provides an overview of the user data scripts used to provision GraphDB and form a cluster.
Each script corresponds to a specific functionality required during resource creation.

All scripts are designed to be run on AWS EC2 instances and must be executed in a precise order.

Each script is a template file (*.sh.tpl) that contains the necessary commands and configurations.
These templates are used by Terraform to generate the actual user data scripts deployed to the instances during provisioning.

# 00_wait_node_count.sh.tpl
This script handles waiting for nodes and disk during instance refresh

# 01_disk_management.sh.tpl
This script manages the EBS volumes associated with the instance.
It searches for available volumes and creates new ones if none are found.
In the end it attaches the found/created volume and configures it.

# 02_dns_provisioning.sh.tpl
This script handles the setup of a DNS record for the instance.
It interacts with Route 53 to create DNS records and ensures that they are properly configured and updated.

The node name is based on the availability zone id, and the number of graphdb instances running in the same zone, starting from zero.

For example, in a typical 3 node deployment, where each node is in a different Availability zone the nodes would be named:
`node-0-zone-1.graphdb.cluster`, `node-0-zone-2.graphdb.cluster`, `node-0-zone-3.graphdb.cluster`

# 03_gdb_conf_overrides.sh.tpl
This script applies configuration overrides for GraphDB.
It modifies configuration files or applies settings specific to GraphDB to customize its behavior.
In addition it will append the `.env` and `graphdb.properties` files with values provided via
the `graphdb_properties_path` and `graphdb_java_options` variables specified in the `tfvars`.

# 04_gdb_backup_conf.sh.tpl
This script provisions the backup script for GraphDB.
It sets up backup schedules, destination and other related configurations.
Configures a cron job to run the script on a specified interval.

# 05_linux_overrides.sh.tpl
This script applies overrides specific to the Linux operating system running on the instance.
It sets `net.ipv4.tcp_keepalive_time` and `fs.file-max`

# 06_cloudwatch_setup.sh.tpl
This script sets up monitoring and logging using AWS CloudWatch.
It provisions a pre-defined configuration for the CloudWatch agent.

# 07_cluster_setup.sh.tpl
This script handles the setup of cluster configurations.
It depends on the successful execution of `02_dns_provisioning.sh.tpl`, as logic for cluster setup relies on the DNS records.
It includes steps to form a cluster as well as some check for a successful cluster creation.

# 08_node_rejoin.sh.tpl
This script handles the rejoining of nodes to a cluster.
It ensures that nodes can rejoin the cluster after being recreated in a new Availability zone.
It also handles new nodes joining the existing cluster.

