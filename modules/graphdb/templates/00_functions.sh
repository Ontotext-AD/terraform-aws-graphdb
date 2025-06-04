#!/usr/bin/env bash

# Function to log messages with a timestamp
log_with_timestamp() {
  echo "$(date '+%Y-%m-%d %H:%M:%S'): $1"
}

ENABLE_ASG_WAIT=${enable_asg_wait}

# Function to check ASG node counts
wait_for_asg_nodes() {
  local ASG_NAME="$1"
  local RETRY_DELAY=10
  local MAX_RETRIES=65
  local RETRY_COUNT=0

  # Get the desired capacity of the ASG
  local NODE_COUNT
  NODE_COUNT=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$ASG_NAME" \
    --query "AutoScalingGroups[0].DesiredCapacity" \
    --output text)

  # Check if NODE_COUNT is not an integer
  if ! [[ "$NODE_COUNT" =~ ^[0-9]+$ ]]; then
  log_with_timestamp "Error: Unable to retrieve valid Desired Capacity for ASG: $ASG_NAME. Received value: $NODE_COUNT."
  exit 1
  fi

  log_with_timestamp "Checking ASG node count for $ASG_NAME with desired node count: $NODE_COUNT"

  while true; do
    # Check InService and Terminating states via ASG
    local IN_SERVICE_NODE_COUNT
    IN_SERVICE_NODE_COUNT=$(aws autoscaling describe-auto-scaling-groups \
      --auto-scaling-group-names "$ASG_NAME" \
      --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'] | length(@)" \
      --output text)

    local TERMINATING_NODE_COUNT
    TERMINATING_NODE_COUNT=$(aws autoscaling describe-auto-scaling-groups \
      --auto-scaling-group-names "$ASG_NAME" \
      --query "AutoScalingGroups[0].Instances[?LifecycleState=='Terminating'] | length(@)" \
      --output text)

    local SHUTTING_DOWN_NODE_COUNT
    SHUTTING_DOWN_NODE_COUNT=$(aws ec2 describe-instances \
      --filters "Name=instance-state-name,Values=shutting-down" \
      --query "Reservations[].Instances[].InstanceId | length(@)" \
      --output text)

    log_with_timestamp "InService: $IN_SERVICE_NODE_COUNT, Terminating: $TERMINATING_NODE_COUNT, Shutting-down: $SHUTTING_DOWN_NODE_COUNT, Desired: $NODE_COUNT"

    if [[ -z "$IN_SERVICE_NODE_COUNT" || "$IN_SERVICE_NODE_COUNT" -le "$NODE_COUNT" ]] \
      && [[ "$TERMINATING_NODE_COUNT" -eq 0 ]] \
      && [[ "$SHUTTING_DOWN_NODE_COUNT" -eq 0 ]]; then
      log_with_timestamp "Conditions met: InService <= $NODE_COUNT, no Terminating, no Shutting-down. Proceeding..."
      break
    else
      if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
        log_with_timestamp "Error: Maximum retry attempts reached. Exiting..."
        exit 1
      fi

      log_with_timestamp "Conditions not met. Waiting... (InService: $IN_SERVICE_NODE_COUNT, Terminating: $TERMINATING_NODE_COUNT, Shutting-down: $SHUTTING_DOWN_NODE_COUNT)"
      sleep "$RETRY_DELAY"
      RETRY_COUNT=$((RETRY_COUNT + 1))
    fi
  done
}

# Function which waits for all DNS records to be created
wait_dns_records() {
  local ZONE_ID="$1"
  local ROUTE53_ZONE_DNS_NAME="$2"
  local ASG_NAME="$3"
  local NODE_COUNT=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG_NAME" --query "AutoScalingGroups[0].DesiredCapacity" --output text)
  local all_dns_records=($(aws route53 list-resource-record-sets --hosted-zone-id "$${ZONE_ID}" --query "ResourceRecordSets[?contains(Name, '.$${ROUTE53_ZONE_DNS_NAME}') == \`true\`].Name" --output text))
  local all_dns_records_count="$${#all_dns_records[@]}"

  if [ "$${all_dns_records_count}" -ne $${NODE_COUNT} ]; then
    sleep 5
    log_with_timestamp "Private DNS zone record count is $${all_dns_records_count}, expecting $${NODE_COUNT}"
    wait_dns_records "$ZONE_ID" "$ROUTE53_ZONE_DNS_NAME" "$ASG_NAME"
  else
    log_with_timestamp "Private DNS zone record count is $${all_dns_records_count}, expecting $${NODE_COUNT}"
  fi
}

# Function which checks if GraphDB is started, we assume it is when the infrastructure endpoint is reached
check_gdb() {
  if [ -z "$1" ]; then
    log_with_timestamp "Error: IP address or hostname is not provided."
    return 1
  fi

  local gdb_address="http://$1:7201/rest/monitor/infrastructure"
  if curl -s --head -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" --fail "$${gdb_address}" >/dev/null; then
    log_with_timestamp "Success, GraphDB node $${gdb_address} is available"
    return 0
  else
    log_with_timestamp "GraphDB node $${gdb_address} is not available yet"
    return 1
  fi
}

check_all_dns_records() {
  local ZONE_ID="$1"
  local ROUTE53_ZONE_DNS_NAME="$2"
  local RETRY_DELAY="$${3:-5}"  # Default retry delay to 5 seconds if not provided

  # Retrieve existing DNS records
  local EXISTING_DNS_RECORDS
  EXISTING_DNS_RECORDS=$(aws route53 list-resource-record-sets --hosted-zone-id "$${ZONE_ID}" --query "ResourceRecordSets[?contains(Name, '.$${ROUTE53_ZONE_DNS_NAME}') == \`true\`].Name")

  # Convert the output into an array
  local EXISTING_DNS_RECORDS_ARRAY
  readarray -t EXISTING_DNS_RECORDS_ARRAY <<<"$(echo "$EXISTING_DNS_RECORDS" | jq -r '.[] | rtrimstr(".")')"

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
}

configure_graphdb_security() {
  local GRAPHDB_PASSWORD=$1
  local GRAPHDB_URL=$${2:-"http://localhost:7201"}

  IS_SECURITY_ENABLED=$(curl -s -X GET \
    --header 'Accept: application/json' \
    -u "admin:$GRAPHDB_PASSWORD" \
    "$${GRAPHDB_URL}/rest/security")

  # Check if GDB security is enabled
  if [[ $IS_SECURITY_ENABLED == "true" ]]; then
    log_with_timestamp "Security is enabled"
  else
    # Set the admin password
    SET_PASSWORD=$(
      curl --location -s -w "%%{http_code}" \
        --request PATCH "$${GRAPHDB_URL}/rest/security/users/admin" \
        --header 'Content-Type: application/json' \
        --data "{ \"password\": \"$GRAPHDB_PASSWORD\" }"
    )
    if [[ "$SET_PASSWORD" == 200 ]]; then
      log_with_timestamp "Set GraphDB password successfully"
    else
      log_with_timestamp "Failed setting GraphDB password. Please check the logs!"
    fi

    # Enable the security
    ENABLED_SECURITY=$(curl -X POST -s -w "%%{http_code}" \
      --header 'Content-Type: application/json' \
      --header 'Accept: */*' \
      -d 'true' "$${GRAPHDB_URL}/rest/security")

    if [[ "$ENABLED_SECURITY" == 200 ]]; then
      log_with_timestamp "Enabled GraphDB security successfully"
    else
      log_with_timestamp "Failed enabling GraphDB security. Please check the logs!"
    fi
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
  else
    echo "License is mounted"
  fi
}

# Function which waits for GraphDB to start, checking every 10 seconds up to 5 minutes
wait_for_local_gdb() {
  local gdb_address="http://localhost:7201/protocol"
  local max_wait_time=300  # 5 minutes
  local wait_interval=10   # Check every 10 seconds
  local elapsed_time=0

  while [ $elapsed_time -lt $max_wait_time ]; do
    if curl -s --head -u "admin:$${GRAPHDB_ADMIN_PASSWORD}" --fail "$${gdb_address}" >/dev/null; then
      log_with_timestamp "Success, GraphDB instance is available at $gdb_address"
      return 0  # Success
    fi

    # Wait for the specified interval
    sleep $wait_interval
    elapsed_time=$((elapsed_time + wait_interval))
    log_with_timestamp "Waiting for GraphDB to start, elapsed time: $${elapsed_time}s"
  done

  log_with_timestamp "Error: GraphDB instance at $gdb_address not available after waiting for $max_wait_time seconds."
  return 1
}
