#!/usr/bin/env bash

# This script focuses on the GraphDB node rejoining the cluster if the scale set spawns a new VM instance with a new volume.
#
# It performs the following tasks:
#   * Rejoins the node to the cluster if raft folder is not found or empty

set -o errexit
set -o nounset
set -o pipefail

# Imports helper functions
source /var/lib/cloud/instance/scripts/part-002

NODE_COUNT=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${name} --query "AutoScalingGroups[0].DesiredCapacity" --output text)

# Don't attempt to form a cluster if the node count is 1
if [ "$${NODE_COUNT}" == 1 ]; then
  log_with_timestamp "Single node deployment, skipping node cluster rejoin "
  exit 0
fi

GRAPHDB_ADMIN_PASSWORD=$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/admin_password" --with-decryption --query "Parameter.Value" --output text | base64 -d)
CURRENT_NODE_NAME=$(hostname)
LEADER_NODE=""
RAFT_DIR="/var/opt/graphdb/node/data/raft"

# Get existing DNS records from Route53 which contain .graphdb.cluster in their name
EXISTING_RECORDS=$(aws route53 list-resource-record-sets --hosted-zone-id "${zone_id}" --query "ResourceRecordSets[?contains(Name, '.graphdb.cluster') == \`true\`].Name")
# Use jq to process the JSON output, remove the last dot from each element, and convert it to an array
EXISTING_RECORDS=$(echo "$EXISTING_RECORDS" | jq -r '.[] | rtrimstr(".")')
# Convert the output into an array
readarray -t EXISTING_RECORDS_ARRAY <<<"$EXISTING_RECORDS"

# Function to check if GraphDB is running
check_gdb() {
  local gdb_address="$1:7201/rest/monitor/infrastructure"
  if curl -s --head -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" --fail "$gdb_address" >/dev/null; then
    log_with_timestamp "Success, GraphDB node $gdb_address is available"
    return 0
  else
    log_with_timestamp "GraphDB node $gdb_address is not available yet"
    return 1
  fi
}

# This function should be used only after the Leader node is found
get_cluster_state() {
  curl_response=$(curl "http://$${LEADER_NODE}/rest/monitor/cluster" -s -u "admin:$GRAPHDB_ADMIN_PASSWORD")
  nodes_in_cluster=$(echo "$curl_response" | grep -oP 'graphdb_nodes_in_cluster \K\d+')
  nodes_in_sync=$(echo "$curl_response" | grep -oP 'graphdb_nodes_in_sync \K\d+')
  echo "$nodes_in_cluster $nodes_in_sync"
}

# Function to wait until total quorum is achieved
wait_for_total_quorum() {
  while true; do
    cluster_metrics=$(get_cluster_state)
    nodes_in_cluster=$(echo "$cluster_metrics" | awk '{print $1}')
    nodes_in_sync=$(echo "$cluster_metrics" | awk '{print $2}')

    if [ "$nodes_in_sync" -eq "$nodes_in_cluster" ]; then
      log_with_timestamp "Total quorum achieved: graphdb_nodes_in_sync: $nodes_in_sync equals graphdb_nodes_in_cluster: $nodes_in_cluster"
      break
    else
      log_with_timestamp "Waiting for total quorum... (graphdb_nodes_in_sync: $nodes_in_sync, graphdb_nodes_in_cluster: $nodes_in_cluster)"
      sleep 30
    fi
  done
}

# Function to add a node to the existing cluster
join_cluster() {

  echo "#########################"
  echo "#    Joining cluster    #"
  echo "#########################"

  # Waits for all nodes to be available (Handles rolling upgrades)
  for node in "$${EXISTING_RECORDS_ARRAY[@]}"; do
    while ! check_gdb "$node"; do
      log_with_timestamp "Waiting for GDB $node to start"
      sleep 5
    done
  done

  # Iterates all nodes and looks for a Leader node to extract its address.
  while [ -z "$LEADER_NODE" ]; do
    for node in "$${EXISTING_RECORDS_ARRAY[@]}"; do
      endpoint="http://$node:7201/rest/cluster/group/status"
      log_with_timestamp "Checking leader status for $node"

      # Gets the address of the node if nodeState is LEADER, grpc port is returned therefore we replace port 7300 to 7200
      LEADER_ADDRESS=$(curl -s "$endpoint" -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" | jq -r '.[] | select(.nodeState == "LEADER") | .address' | sed 's/7301/7201/')
      if [ -n "$${LEADER_ADDRESS}" ]; then
        LEADER_NODE=$LEADER_ADDRESS
        log_with_timestamp "Found leader address $LEADER_ADDRESS"
        break 2 # Exit both loops
      else
        log_with_timestamp "No leader found at $node"
      fi
    done

    log_with_timestamp "No leader found on any node. Retrying..."
    sleep 5
  done

  log_with_timestamp "Trying to delete $CURRENT_NODE_NAME"
  # Removes node if already present in the cluster config
  curl -X DELETE -s \
    --fail-with-body \
    -o "/dev/null" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -w "%%{http_code}" \
    -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" \
    -d "{\"nodes\": [\"$${CURRENT_NODE_NAME}:7301\"]}" \
    "http://$${LEADER_NODE}/rest/cluster/config/node" || true

  # Waits for total quorum of the cluster before continuing with joining the cluster
  wait_for_total_quorum

  log_with_timestamp "Attempting to add $${CURRENT_NODE_NAME}:7301 to the cluster"

  retry_count=0
  max_retries=3
  retry_interval=300 # 5 minutes in seconds

  while [ $retry_count -lt $max_retries ]; do
    # This operation might take a while depending on the size of the repositories.
    CURL_MAX_REQUEST_TIME=21600 # 6 hours
    ADD_NODE=$(
      curl -X POST -s \
        -m $CURL_MAX_REQUEST_TIME \
        -w "%%{http_code}" \
        -o "/dev/null" \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json' \
        -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" \
        -d "{\"nodes\": [\"$${CURRENT_NODE_NAME}:7301\"]}" \
        "http://$${LEADER_NODE}/rest/cluster/config/node"
    )

    if [[ "$ADD_NODE" == 200 ]]; then
      log_with_timestamp "$${CURRENT_NODE_NAME} was successfully added to the cluster."
      break
    else
      log_with_timestamp "Node $${CURRENT_NODE_NAME} failed to join the cluster, attempt $((retry_count + 1)) of $max_retries."
      if [ $retry_count -lt $((max_retries - 1)) ]; then
        log_with_timestamp "Retrying in 5 minutes..."
        sleep $retry_interval
      fi
      retry_count=$((retry_count + 1))
    fi
  done

  if [[ "$ADD_NODE" != 200 ]]; then
    log_with_timestamp "Node $${CURRENT_NODE_NAME} failed to join the cluster after $max_retries attempts, check the logs!"
  fi
}
# Check if the Raft directory exists
if [ ! -d "$RAFT_DIR" ]; then
  log_with_timestamp "$RAFT_DIR folder is missing, waiting..."

  # The initial provisioning of scale set in AWS may take a while
  # therefore we need to be sure that this is not triggered before the first cluster initialization.
  # Wait for 150 seconds, break if the folder appears (Handles cluster initialization).

  for i in {1..30}; do
    if [ ! -d "$RAFT_DIR" ]; then
      log_with_timestamp "Raft directory not found yet. Waiting (attempt $i of 30)..."
      sleep 5
      if [ $i == 30 ]; then
        log_with_timestamp "$RAFT_DIR folder is not found, joining node to cluster"
        join_cluster
      fi
    else
      log_with_timestamp "Found Raft directory"
      if [ -z "$(ls -A $RAFT_DIR)" ]; then
        # TODO check if the data folder is empty as well, otherwise this will fail.
        log_with_timestamp "$RAFT_DIR folder is empty, joining node to cluster"
        join_cluster
      else
        break
      fi
    fi
  done
fi

echo "###########################"
echo "#    Script completed     #"
echo "###########################"
