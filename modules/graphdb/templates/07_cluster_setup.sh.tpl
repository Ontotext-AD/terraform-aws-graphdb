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

# Function to print messages with timestamps
log_with_timestamp() {
  echo "$(date '+%Y-%m-%d %H:%M:%S'): $1"
}

NODE_DNS_RECORD=$(cat /var/opt/graphdb/node_dns)
GRAPHDB_ADMIN_PASSWORD=$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/admin_password" --with-decryption --query "Parameter.Value" --output text | base64 -d)
RETRY_DELAY=5
MAX_RETRIES=10

echo "###########################"
echo "#    Starting GraphDB     #"
echo "###########################"

# Don't attempt to form a cluster if the node count is 1
if [ "${node_count}" == 1 ]; then
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

# Function which waits for all DNS records to be created
wait_dns_records() {
  local all_dns_records=($(aws route53 list-resource-record-sets --hosted-zone-id "${zone_id}" --query "ResourceRecordSets[?contains(Name, '.graphdb.cluster') == \`true\`].Name" --output text))
  local all_dns_records_count="$${#all_dns_records[@]}"

  if [ "$${all_dns_records_count}" -ne ${node_count} ]; then
    sleep 5
    log_with_timestamp "Private DNS zone record count is $${all_dns_records_count}, expecting ${node_count}"
    wait_dns_records
  else
    log_with_timestamp "Private DNS zone record count is $${all_dns_records_count}, expecting ${node_count}"
  fi
}

# Function which checks if GraphDB is started, we assume it is when the infrastructure endpoint is reached
check_gdb() {
  if [ -z "$1" ]; then
    log_with_timestamp "Error: IP address or hostname is not provided."
    return 1
  fi

  local gdb_address="$1:7201/rest/monitor/infrastructure"
  if curl -s --head -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" --fail "$${gdb_address}" >/dev/null; then
    log_with_timestamp "Success, GraphDB node $${gdb_address} is available"
    return 0
  else
    log_with_timestamp "GraphDB node $${gdb_address} is not available yet"
    return 1
  fi
}

wait_dns_records

# Existing records are returned with . at the end
EXISTING_DNS_RECORDS=$(aws route53 list-resource-record-sets --hosted-zone-id "${zone_id}" --query "ResourceRecordSets[?contains(Name, '.graphdb.cluster') == \`true\`].Name")
# Convert the output into an array
readarray -t EXISTING_DNS_RECORDS_ARRAY <<<$(echo "$EXISTING_DNS_RECORDS" | jq -r '.[] | rtrimstr(".")')
# Builds grpc addresses for all nodes registered in Route53
CLUSTER_ADDRESS_GRPC=$(echo "$EXISTING_DNS_RECORDS" | jq -r '[ .[] | rtrimstr(".") + ":7301" ]')
# Determine with is the lowest instance ID
SORTED_INSTANCE_IDS=($(echo "$${EXISTING_DNS_RECORDS_ARRAY[@]}" | tr ' ' '\n' | sort -n))
LOWEST_INSTANCE_ID=$${SORTED_INSTANCE_IDS[0]}

# Wait for all instances to be running
for record in "$${EXISTING_DNS_RECORDS_ARRAY[@]}"; do
  log_with_timestamp "Pinging $record"
  if [ -n "$record" ]; then
    while ! check_gdb "$record"; do
      log_with_timestamp "Waiting for GDB $record to start"
      sleep "$RETRY_DELAY"
    done
  else
    log_with_timestamp "Error: address is empty."
  fi
done

log_with_timestamp "All GDB instances are available."

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
        curl -X POST -s http://localhost:7201/rest/cluster/config \
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

# Function which enables the admin password and enables the security in GraphDB
enable_security() {
  echo "#############################################################"
  echo "#    Changing admin user password and enabling security     #"
  echo "#############################################################"

  # Set the admin password
  local set_password=$(
    curl --location -s -w "%%{http_code}" \
      --request PATCH 'http://localhost:7200/rest/security/users/admin' \
      --header 'Content-Type: application/json' \
      --data "{ \"password\": \"$${GRAPHDB_ADMIN_PASSWORD}\" }"
  )
  if [[ "$set_password" == 200 ]]; then
    log_with_timestamp "Set GraphDB password successfully"
  else
    log_with_timestamp "Failed setting GraphDB password. Please check the logs!"
    return 1
  fi

  # Enable the security
  local enable_security=$(
    curl -X POST -s -w "%%{http_code}" \
      --header 'Content-Type: application/json' \
      --header 'Accept: */*' \
      -d 'true' 'http://localhost:7200/rest/security'
  )

  if [[ "$enable_security" == 200 ]]; then
    log_with_timestamp "Enabled GraphDB security successfully"
  else
    log_with_timestamp "Failed enabling GraphDB security. Please check the logs!"
    return 1
  fi
}

# Function which checks if the GraphDB security is enabled
check_security_status() {
  local is_security_enabled=$(
    curl -s -X GET \
      --header 'Accept: application/json' \
      -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" \
      'http://localhost:7200/rest/security'
  )

  # Check if GDB security is enabled
  if [[ $is_security_enabled == "true" ]]; then
    log_with_timestamp "Security is enabled"
  else
    log_with_timestamp "Security is not enabled"
    enable_security
  fi
}

# Function to check if the GraphDB license has been applied
check_license() {
  # Define the URL to check
  local URL="http://localhost:7201/rest/graphdb-settings/license"

  # Send an HTTP GET request and store the response in a variable
  local response=$(curl -s "$URL")

  # Check if the response contains the word "free"
  if [[ "$response" == *"free"* ]]; then
    log_with_timestamp "Free license detected, EE license required, exiting!"
    exit 1
  fi
}

check_license

#  Only the instance with the lowest ID would attempt to create the cluster
if [ $NODE_DNS_RECORD == $LOWEST_INSTANCE_ID ]; then
  create_cluster
  find_leader_node
  check_security_status
else
  log_with_timestamp "Node $NODE_DNS_RECORD is not the lowest instance, skipping cluster creation."
fi
