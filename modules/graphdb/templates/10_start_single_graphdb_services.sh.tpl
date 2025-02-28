#!/usr/bin/env bash

# This script performs the following actions:
# * Retrieves necessary information from AWS, such as the GraphDB admin password.
# * Starts and enables the GraphDB service and GraphDB cluster proxy services.
# * Waits for the availability of the local GraphDB instance.
# * Configures the GraphDB instance for secure operation using the provided admin password.

set -o errexit
set -o nounset
set -o pipefail

# Imports helper functions
source /var/lib/cloud/instance/scripts/part-002

GRAPHDB_ADMIN_PASSWORD=$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/admin_password" --with-decryption --query "Parameter.Value" --output text | base64 -d)

echo "###########################"
echo "#    Starting GraphDB     #"
echo "###########################"

log_with_timestamp "Starting Graphdb"
systemctl daemon-reload
systemctl start graphdb

echo "##############################"
echo "#    Configuring GraphDB     #"
echo "##############################"

wait_for_local_gdb
configure_graphdb_security "$GRAPHDB_ADMIN_PASSWORD"

echo "###########################"
echo "#    Script completed     #"
echo "###########################"
