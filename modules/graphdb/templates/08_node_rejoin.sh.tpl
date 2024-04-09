#!/usr/bin/env bash

# This script focuses on the GraphDB node rejoining the cluster if the scale set spawns a new VM instance with a new volume.
#
# It performs the following tasks:
#   * Rejoins the node to the cluster if raft folder is not found or empty

set -o errexit
set -o nounset
set -o pipefail

# Don't attempt to form a cluster if the node count is 1
if [ "${node_count}" == 1 ]; then
  echo "Single node deployment, skipping node cluster rejoin "
  exit 0
fi

GRAPHDB_ADMIN_PASSWORD=$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/admin_password" --with-decryption --query "Parameter.Value" --output text | base64 -d)
CURRENT_NODE_NAME=$(hostname)
LEADER_NODE=""
RAFT_DIR="/var/opt/graphdb/node/data/raft"
RETRY_DELAY=5
MAX_RETRIES=10

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
    echo "Success, GraphDB node $gdb_address is available"
    return 0
  else
    echo "GraphDB node $gdb_address is not available yet"
    return 1
  fi
}

# Function to add a node to the existing cluster
rejoin_cluster() {

  echo "#############################"
  echo "#    Rejoin cluster node    #"
  echo "#############################"

  # Waits for all nodes to be available (Handles rolling upgrades)
  for node in "$${EXISTING_RECORDS_ARRAY[@]}"; do
    while ! check_gdb "$node"; do
      echo "Waiting for GDB $node to start"
      sleep 5
    done
  done

  # Iterates all nodes and looks for a Leader node to extract its address.
  while [ -z "$LEADER_NODE" ]; do
    for node in "$${EXISTING_RECORDS_ARRAY[@]}"; do
      endpoint="http://$node:7201/rest/cluster/group/status"
      echo "Checking leader status for $node"

      # Gets the address of the node if nodeState is LEADER, grpc port is returned therefor we replace port 7300 to 7200
      LEADER_ADDRESS=$(curl -s "$endpoint" -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" | jq -r '.[] | select(.nodeState == "LEADER") | .address' | sed 's/7301/7201/')
      if [ -n "$${LEADER_ADDRESS}" ]; then
        LEADER_NODE=$LEADER_ADDRESS
        echo "Found leader address $LEADER_ADDRESS"
        break 2 # Exit both loops
      else
        echo "No leader found at $node"
      fi
    done

    echo "No leader found on any node. Retrying..."
    sleep 5
  done

  echo "Attempting to rejoin the cluster"
  # Step 1: Remove the node from the cluster.
  echo "Attempting to delete $${CURRENT_NODE_NAME}:7301 from the cluster"

  # To handle cluster scale up we return true if the delete operation fails.
  curl -X DELETE -s \
    --fail-with-body \
    -o "/dev/null" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -w "%%{http_code}" \
    -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" \
    -d "{\"nodes\": [\"$${CURRENT_NODE_NAME}:7301\"]}" \
    "http://$${LEADER_NODE}/rest/cluster/config/node" || true

  # Step 2: Add the current node to the cluster with the same address.
  echo "Attempting to add $${CURRENT_NODE_NAME}:7301 to the cluster"
  # This operation might take a while depending on the size of the repositories.
  CURL_MAX_REQUEST_TIME=21600 # 6 hours

  ADD_NODE=$(
    curl -X POST -s \
      -m $CURL_MAX_REQUEST_TIME \
      -o "/dev/null" \
      -H 'Content-Type: application/json' \
      -H 'Accept: application/json' \
      -w "%%{http_code}" \
      -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" \
      -d"{\"nodes\": [\"$${CURRENT_NODE_NAME}:7301\"]}" \
      "http://$${LEADER_NODE}/rest/cluster/config/node"
  )

  if [[ "$ADD_NODE" == 200 ]]; then
    echo "$${CURRENT_NODE_NAME} was successfully added to the cluster."
  else
    echo "Node $${CURRENT_NODE_NAME} failed to rejoin the cluster, check the logs!"
  fi
}

# Check if the Raft directory exists
if [ ! -d "$RAFT_DIR" ]; then
  echo "$RAFT_DIR folder is missing, waiting..."

  # The initial provisioning of scale set in AWS may take a while
  # therefore we need to be sure that this is not triggered before the first cluster initialization.
  # Wait for 150 seconds, break if the folder appears (Handles cluster initialization).

  for i in {1..30}; do
    if [ ! -d "$RAFT_DIR" ]; then
      echo "Raft directory not found yet. Waiting (attempt $i of 30)..."
      sleep 5
      if [ $i == 30 ]; then
        echo "$RAFT_DIR folder is not found, rejoining node to cluster"
        rejoin_cluster
      fi
    else
      echo "Found Raft directory"
      if [ -z "$(ls -A $RAFT_DIR)" ]; then
        echo "$RAFT_DIR folder is empty, rejoining node to cluster"
        rejoin_cluster
      else
        break
      fi
    fi
  done
fi

echo "###########################"
echo "#    Script completed     #"
echo "###########################"
