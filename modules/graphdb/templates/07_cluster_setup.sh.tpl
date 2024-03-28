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

NODE_DNS=$(cat /tmp/node_dns)
IMDS_TOKEN=$(curl -Ss -H "X-aws-ec2-metadata-token-ttl-seconds: 6000" -XPUT 169.254.169.254/latest/api/token)
INSTANCE_ID=$(curl -Ss -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" 169.254.169.254/latest/meta-data/instance-id)
GRAPHDB_ADMIN_PASSWORD=$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/admin_password" --with-decryption --query "Parameter.Value" --output text | base64 -d)
VPC_ID=$(aws ec2 describe-instances --instance-id "$${INSTANCE_ID}" --query 'Reservations[0].Instances[0].VpcId' --output text)

RETRY_DELAY=5
MAX_RETRIES=10

echo "###########################"
echo "#    Starting GraphDB     #"
echo "###########################"

# the proxy service is set up in the AMI but not enabled, so we enable and start it
systemctl daemon-reload
systemctl start graphdb
systemctl enable graphdb-cluster-proxy.service
systemctl start graphdb-cluster-proxy.service

#####################
#   Cluster setup   #
#####################

# Checks if GraphDB is started, we assume it is when the infrastructure endpoint is reached
check_gdb() {
  if [ -z "$1" ]; then
    echo "Error: IP address or hostname is not provided."
    return 1
  fi

  local gdb_address="$1:7201/rest/monitor/infrastructure"
  if curl -s --head -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" --fail "$${gdb_address}" >/dev/null; then
    echo "Success, GraphDB node $${gdb_address} is available"
    return 0
  else
    echo "GraphDB node $${gdb_address} is not available yet"
    return 1
  fi
}

# Waits for 3 DNS records to be available
wait_dns_records() {
  ALL_DNS_RECORDS=($(aws ec2 describe-instances --filters "Name=vpc-id,Values=$${VPC_ID}" --query 'Reservations[*].Instances[*].[PrivateDnsName]' --output text))
  ALL_DNS_RECORDS_COUNT="$${#ALL_DNS_RECORDS[@]}"

  if [ "$${ALL_DNS_RECORDS_COUNT}" -ne 3 ]; then
    sleep 5
    wait_dns_records
  else
    echo "Private DNS zone record count is $${ALL_DNS_RECORDS_COUNT}"
  fi
}

wait_dns_records

# Check all instances are running
for record in "$${ALL_DNS_RECORDS[@]}"; do
  echo "Pinging $record"

  if [ -n "$record" ]; then
    while ! check_gdb "$record"; do
      echo "Waiting for GDB $record to start"
      sleep "$RETRY_DELAY"
    done
  else
    echo "Error: address is empty."
  fi
done

echo "All GDB instances are available."

# Determine the order of GraphDB instances in the cluster by querying Route 53 DNS records.
# This is done because we don't want the 3 nodes to attempt to create the same cluster.
EXISTING_RECORDS=($(aws route53 list-resource-record-sets --hosted-zone-id "${zone_id}" --query "ResourceRecordSets[?contains(Name, '.graphdb.cluster') == \`true\`].Name" --output text | sort -n))
# Extract individual DNS names for the GraphDB cluster nodes.
NODE1="$${EXISTING_RECORDS[0]%?}"
NODE2="$${EXISTING_RECORDS[1]%?}"
NODE3="$${EXISTING_RECORDS[2]%?}"

# Check if the current GraphDB node is the first one in the cluster (lowest instance).
if [ $NODE_DNS == $NODE1 ]; then

  echo "##################################"
  echo "#    Beginning cluster setup     #"
  echo "##################################"

  echo "Attempting to create a GraphDB cluster by configuring cluster nodes."
  # Will retry several times in case 000 is returned as a HTTP response code
  for ((i = 1; i <= $MAX_RETRIES; i++)); do
    # /rest/monitor/cluster will return 200 only if a cluster exists, 503 if no cluster is set up.
    IS_CLUSTER=$(
      curl -s -o /dev/null \
        -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" \
        -w "%%{http_code}" \
        http://localhost:7201/rest/monitor/cluster
    )

    # Check if GraphDB is part of a cluster; 000 indicates no HTTP code was received.
    if [[ "$IS_CLUSTER" == 000 ]]; then
      echo "Retrying ($i/$MAX_RETRIES) after $RETRY_DELAY seconds..."
      sleep $RETRY_DELAY
    elif [ "$IS_CLUSTER" == 503 ]; then
      # Create the GraphDB cluster configuration if it does not exist.
      CLUSTER_CREATE=$(
        curl -X POST -s http://localhost:7201/rest/cluster/config \
          -o "/dev/null" \
          -w "%%{http_code}" \
          -H 'Content-type: application/json' \
          -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" \
          -d "{\"nodes\": [\"$${NODE1}:7301\",\"$${NODE2}:7301\",\"$${NODE3}:7301\"]}"
      )
      if [[ "$CLUSTER_CREATE" == 201 ]]; then
        echo "GraphDB cluster successfully created!"
        break
      fi
    elif [ "$IS_CLUSTER" == 200 ]; then
      echo "Cluster exists"
      break
    elif [ "$IS_CLUSTER" == 412 ]; then
      echo "Cluster precondition/s are not met"
      exit 1
    else
      echo "Something went wrong! Check the log files."
      # Do not continue if the cluster creation fails for another reason.
      exit 1
    fi
  done

  echo "###########################################################"
  echo "#    Changing admin user password and enable security     #"
  echo "###########################################################"

  retry_count=0
  max_retries=120
  LEADER_NODE=""
  # Before enabling security a Leader must be elected. Iterates all nodes and looks for a node with status Leader.
  while [ -z "$LEADER_NODE" ]; do
    if [ "$retry_count" -ge "$max_retries" ]; then
      echo "Max retry limit reached. Leader node not found."
      echo "Exiting..."
      exit 1
    fi
    NODES=($NODE1 $NODE2 $NODE3)
    for node in "$${NODES[@]}"; do
      endpoint="http://$node:7201/rest/cluster/group/status"
      echo "Checking leader status for $node"

      # Gets the address of the node if nodeState is LEADER.
      LEADER_ADDRESS=$(curl -s "$endpoint" -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" | jq -r '.[] | select(.nodeState == "LEADER") | .address')
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
    ((retry_count++))
  done

  IS_SECURITY_ENABLED=$(curl -s -X GET \
    --header 'Accept: application/json' \
    -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" \
    'http://localhost:7200/rest/security')

  # Check if GDB security is enabled
  if [[ $IS_SECURITY_ENABLED == "true" ]]; then
    echo "Security is enabled"
  else
    # Set the admin password
    SET_PASSWORD=$(
      curl --location -s -w "%%{http_code}" \
        --request PATCH 'http://localhost:7200/rest/security/users/admin' \
        --header 'Content-Type: application/json' \
        --data "{ \"password\": \"$${GRAPHDB_ADMIN_PASSWORD}\" }"
    )
    if [[ "$SET_PASSWORD" == 200 ]]; then
      echo "Set GraphDB password successfully"
    else
      echo "Failed setting GraphDB password. Please check the logs!"
    fi

    # Enable the security
    ENABLED_SECURITY=$(curl -X POST -s -w "%%{http_code}" \
      --header 'Content-Type: application/json' \
      --header 'Accept: */*' \
      -d 'true' 'http://localhost:7200/rest/security')

    if [[ "$ENABLED_SECURITY" == 200 ]]; then
      echo "Enabled GraphDB security successfully"
    else
      echo "Failed enabling GraphDB security. Please check the logs!"
    fi
  fi
else
  echo "Node $NODE_DNS is not the lowest instance, skipping cluster creation."
fi

echo "###########################"
echo "#    Script completed     #"
echo "###########################"
