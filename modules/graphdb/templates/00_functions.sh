#!/usr/bin/env bash

# Generic helper functions

# Function to print messages with timestamps
log_with_timestamp() {
  echo "$(date '+%Y-%m-%d %H:%M:%S'): $1"
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
