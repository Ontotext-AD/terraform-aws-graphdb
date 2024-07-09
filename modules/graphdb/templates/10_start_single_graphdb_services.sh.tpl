#!/usr/bin/env bash

# This script performs the following actions:
# * Retrieve necessary information from AWS and set variables.
# * Start and enable GraphDB and GraphDB cluster proxy services.
# * Check GraphDB availability for all instances and wait for DNS records.
# * Attempt to create a GraphDB cluster.
# * Change the admin user password and enable security if the node is the leader.

set -o errexit
set -o nounset
set -o pipefail

# Imports helper functions
source /var/lib/cloud/instance/scripts/part-002

NODE_DNS_RECORD=$(cat /var/opt/graphdb/node_dns)
GRAPHDB_ADMIN_PASSWORD=$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/admin_password" --with-decryption --query "Parameter.Value" --output text | base64 -d)
RETRY_DELAY=5

echo "###########################"
echo "#    Starting GraphDB     #"
echo "###########################"

log_with_timestamp "Starting Graphdb"
systemctl daemon-reload
systemctl start graphdb

echo "##############################"
echo "#    Configuring GraphDB     #"
echo "##############################"

wait_dns_records "${zone_id}" "${route53_zone_dns_name}" "${name}"
check_all_dns_records "${zone_id}" "${route53_zone_dns_name}" "$RETRY_DELAY"
configure_graphdb_security "$GRAPHDB_ADMIN_PASSWORD"

echo "###########################"
echo "#    Script completed     #"
echo "###########################"
