#!/usr/bin/env bash

# This script performs the following actions:
# * Retrieve necessary instance metadata using the EC2 metadata service.
# * Obtain the volume ID from a temporary file created by a previous script.
# * Generate a subdomain and construct the full node DNS name using the volume ID and specified DNS zone information.
# * Update the Route 53 hosted zone with an A record for the node's DNS name pointing to its local IPv4 address.
# * Set the hostname of the EC2 instance to the newly created node DNS name.

set -o errexit
set -o nounset
set -o pipefail

# Imports helper functions
source /var/lib/cloud/instance/scripts/part-002

echo "########################"
echo "#   DNS Provisioning   #"
echo "########################"

IMDS_TOKEN=$(curl -Ss -H "X-aws-ec2-metadata-token-ttl-seconds: 6000" -XPUT 169.254.169.254/latest/api/token)
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" 169.254.169.254/latest/meta-data/instance-id)
LOCAL_IPv4=$(curl -Ss -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" 169.254.169.254/latest/meta-data/local-ipv4)
AVAILABILITY_ZONE_ID=$(curl -Ss -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" 169.254.169.254/latest/meta-data/placement/availability-zone-id)
NODE_DNS_PATH="/var/opt/graphdb/node_dns"
# Extract only the numeric part from the AVAILABILITY_ZONE_ID
AVAILABILITY_ZONE_ID_NUMBER="$${AVAILABILITY_ZONE_ID//*-az}"
NODE_NUMBER=1

# Handles instance reboots or recreations when the node has already been part of a cluster
if [ -f $NODE_DNS_PATH ]; then
  log_with_timestamp "Found $NODE_DNS_PATH"
  NODE_DNS_RECORD=$(cat $NODE_DNS_PATH)

  # Check if the existing DNS record is pointing to another IP
  existing_record=$(aws route53 list-resource-record-sets --hosted-zone-id "${route53_zone_id}" --query "ResourceRecordSets[?Name == '$${NODE_DNS_RECORD}.']" --output json)
  existing_ip=$(echo "$existing_record" | jq -r '.[0].ResourceRecords[0].Value')

  if [ "$existing_ip" != "$LOCAL_IPv4" ]; then
    log_with_timestamp "Updating IP address for $NODE_DNS_RECORD"

    aws --cli-connect-timeout 300 route53 change-resource-record-sets \
      --hosted-zone-id "${route53_zone_id}" \
      --change-batch '{"Changes": [{"Action": "UPSERT","ResourceRecordSet": {"Name": "'"$NODE_DNS_RECORD"'","Type": "A","TTL": 60,"ResourceRecords": [{"Value": "'"$LOCAL_IPv4"'"}]}}]}'

    hostnamectl set-hostname "$NODE_DNS_RECORD"
    log_with_timestamp "DNS record for $NODE_DNS_RECORD has been updated"
  else
    log_with_timestamp "DNS record $NODE_DNS_RECORD already points to the correct IP $LOCAL_IPv4"
  fi
else
  log_with_timestamp "$NODE_DNS_PATH does not exist. Checking for non-responding DNS records."

  # Check for non-responding DNS records
  existing_records=$(aws route53 list-resource-record-sets --hosted-zone-id "${route53_zone_id}" --query "ResourceRecordSets[?contains(Name, 'node-')]" --output json)
  for record in $(echo "$existing_records" | jq -r '.[].Name'); do
    record_name=$${record%.}
    record_ip=$(aws route53 list-resource-record-sets --hosted-zone-id "${route53_zone_id}" --query "ResourceRecordSets[?Name == '$${record_name}.']" --output json | jq -r '.[0].ResourceRecords[0].Value')

    found_count=0
    for i in {1..3}; do
      instance_check=$(aws ec2 describe-instances --filters "Name=private-ip-address,Values=$record_ip" --query "Reservations[*].Instances[*].InstanceId" --output text)
      if [ -n "$instance_check" ]; then
        log_with_timestamp "Instance found with IP $record_ip for record $record_name on attempt $i"
        found_count=$((found_count + 1))
      else
        log_with_timestamp "No instance found with IP $record_ip for record $record_name on attempt $i"
      fi

      if [ "$found_count" -ge 3 ]; then
        log_with_timestamp "Instance with IP $record_ip for record $record_name found consistently. Skipping update."
        break
      fi

      sleep 10
    done

    if [ "$found_count" -lt 3 ]; then
      log_with_timestamp "No instance found with IP $record_ip for record $record_name after 3 attempts. Updating to new IP $LOCAL_IPv4"
      aws --cli-connect-timeout 300 route53 change-resource-record-sets \
        --hosted-zone-id "${route53_zone_id}" \
        --change-batch '{"Changes": [{"Action": "UPSERT","ResourceRecordSet": {"Name": "'"$record_name"'","Type": "A","TTL": 60,"ResourceRecords": [{"Value": "'"$LOCAL_IPv4"'"}]}}]}'
      echo "$record_name" >/var/opt/graphdb/node_dns
      hostnamectl set-hostname "$record_name"
      exit 0
    fi
  done

  log_with_timestamp "No non-responding DNS records found. Creating a new DNS record."

  while true; do
    # Concatenate "node" with the extracted number
    NODE_NAME="node-$NODE_NUMBER"

    # Check if the Route 53 record exists for the node name
    DNS_RECORD_TAKEN=$(aws route53 list-resource-record-sets --hosted-zone-id ${route53_zone_id} --query "ResourceRecordSets[?contains(Name, '$NODE_NAME')]" --output text)

    if [ "$DNS_RECORD_TAKEN" ]; then
      log_with_timestamp "Record $NODE_NAME is taken in hosted zone ${route53_zone_id}"
      # Increment node number for the next iteration
      NODE_NUMBER=$((NODE_NUMBER + 1))
    else
      log_with_timestamp "Record $NODE_NAME does not exist in hosted zone ${route53_zone_id}"
      # Forms the full DNS address for the current node
      NODE_DNS_RECORD="$NODE_NAME.${route53_zone_dns_name}"

      # Attempt to create the DNS record
      if aws --cli-connect-timeout 300 route53 change-resource-record-sets \
        --hosted-zone-id "${route53_zone_id}" \
        --change-batch '{"Changes": [{"Action": "CREATE","ResourceRecordSet": {"Name": "'"$NODE_DNS_RECORD"'","Type": "A","TTL": 60,"ResourceRecords": [{"Value": "'"$LOCAL_IPv4"'"}]}}]}' &>/dev/null; then
        log_with_timestamp "DNS record for $NODE_DNS_RECORD has been created"
        hostnamectl set-hostname "$NODE_DNS_RECORD"
        echo "$NODE_DNS_RECORD" >/var/opt/graphdb/node_dns
        break # Exit loop when non-existing node name is found
      else
        log_with_timestamp "Creating DNS record failed for $NODE_NAME, retrying with next available name"
        # Retry with the next node number
        NODE_NUMBER=$((NODE_NUMBER + 1))
      fi
    fi
  done
fi

# Updating the EC2 name tag
aws ec2 create-tags --resources "$INSTANCE_ID" --tags "Key=Name,Value=${name}:$NODE_DNS_RECORD"
