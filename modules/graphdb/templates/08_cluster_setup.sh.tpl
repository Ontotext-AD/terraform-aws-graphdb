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
MAX_RETRIES=10
NODE_COUNT=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${name} --query "AutoScalingGroups[0].DesiredCapacity" --output text)

echo "###########################"
echo "#    Starting GraphDB     #"
echo "###########################"

# Don't attempt to form a cluster if the node count is 1
if [[ "$${NODE_COUNT}" -eq 1 ]]; then
  log_with_timestamp "Starting Graphdb"
  systemctl daemon-reload
  systemctl start graphdb
  log_with_timestamp "Single node deployment, skipping cluster setup."
  exit 0
else
  # The proxy service is set up in the AMI but not enabled, so we enable and start it
  systemctl daemon-reload
  systemctl start graphdb
  systemctl enable graphdb-cluster-proxy.service
  systemctl start graphdb-cluster-proxy.service
fi

#####################
#   Cluster setup   #
#####################

wait_dns_records "${route53_zone_id}" "${route53_zone_dns_name}" "${name}"

# Existing records are returned with . at the end
EXISTING_DNS_RECORDS=$(aws route53 list-resource-record-sets --hosted-zone-id "${route53_zone_id}" --query "ResourceRecordSets[?contains(Name, '.${route53_zone_dns_name}') == \`true\`].Name")
# Convert the output into an array
readarray -t EXISTING_DNS_RECORDS_ARRAY <<<$(echo "$EXISTING_DNS_RECORDS" | jq -r '.[] | rtrimstr(".")')
# Builds grpc addresses for all nodes registered in Route53
CLUSTER_ADDRESS_GRPC=$(echo "$EXISTING_DNS_RECORDS" | jq -r '[ .[] | rtrimstr(".") + ":7301" ]')
# Determine with is the lowest instance ID
SORTED_INSTANCE_IDS=($(echo "$${EXISTING_DNS_RECORDS_ARRAY[@]}" | tr ' ' '\n' | sort -n))
LOWEST_INSTANCE_ID=$${SORTED_INSTANCE_IDS[0]}

check_all_dns_records "${route53_zone_id}" "${route53_zone_dns_name}" "$RETRY_DELAY"

# Function which finds the cluster Leader node
find_leader_node() {
  local retry_count=0
  local max_retries=120
  local leader_node=""

  while [ -z "$leader_node" ]; do
    if [ "$retry_count" -ge "$max_retries" ]; then
      log_with_timestamp "Max retry limit reached. Leader node not found. Exiting..."
      exit 1
    fi

    for node in "$${EXISTING_DNS_RECORDS_ARRAY[@]}"; do
      local endpoint="http://$node:7201/rest/cluster/group/status"
      log_with_timestamp "Checking leader status for $node"

      # Gets the address of the node if nodeState is LEADER.
      local leader_address=$(curl -s "$endpoint" -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" | jq -r '.[] | select(.nodeState == "LEADER") | .address')
      if [ -n "$${leader_address}" ]; then
        leader_node=$leader_address
        log_with_timestamp "Found leader address $leader_address"
        return 0
      else
        log_with_timestamp "No leader found at $node"
      fi
    done

    log_with_timestamp "No leader found on any node. Retrying..."
    sleep 5
    retry_count=$((retry_count + 1))
  done
}

# Function which setups GraphDB cluster
create_cluster() {
  echo "##################################"
  echo "#    Beginning cluster setup     #"
  echo "##################################"

  for ((i = 1; i <= $MAX_RETRIES; i++)); do
    # /rest/monitor/cluster will return 200 only if a cluster exists, 503 if no cluster is set up.
    local is_cluster=$(
      curl -s -o /dev/null \
        -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" \
        -w "%%{http_code}" \
        http://localhost:7201/rest/monitor/cluster
    )

    # Check if GraphDB is part of a cluster; 000 indicates no HTTP code was received.
    if [[ "$is_cluster" == 000 ]]; then
      echo "Retrying ($i/$MAX_RETRIES) after $RETRY_DELAY seconds..."
      sleep $RETRY_DELAY
    elif [ "$is_cluster" == 503 ]; then
      # Create the GraphDB cluster configuration if it does not exist.
      local cluster_create=$(
        curl -X POST -s "http://node-1.${route53_zone_dns_name}:7201/rest/cluster/config" \
          -o "/dev/null" \
          -w "%%{http_code}" \
          -H 'Content-type: application/json' \
          -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" \
          -d "{\"nodes\": $CLUSTER_ADDRESS_GRPC}"
      )
      if [[ "$cluster_create" == 201 ]]; then
        log_with_timestamp "GraphDB cluster successfully created!"
        break
      fi
    elif [ "$is_cluster" == 200 ]; then
      log_with_timestamp "Cluster exists"
      break
    elif [ "$is_cluster" == 412 ]; then
      log_with_timestamp "Cluster precondition/s are not met"
    else
      log_with_timestamp "Something went wrong! Check the log files."
    fi
    sleep $RETRY_DELAY
  done
}

#  Only the instance with the lowest ID would attempt to create the cluster
if [ $NODE_DNS_RECORD == $LOWEST_INSTANCE_ID ]; then
  check_license
  create_cluster
  find_leader_node
  configure_graphdb_security "$GRAPHDB_ADMIN_PASSWORD"
else
  log_with_timestamp "Node $NODE_DNS_RECORD is not the lowest instance, skipping cluster creation."
fi
