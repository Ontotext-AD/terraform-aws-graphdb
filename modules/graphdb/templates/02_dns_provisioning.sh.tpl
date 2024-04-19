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
  echo "Found $NODE_DNS_PATH"
  NODE_DNS_RECORD=$(cat $NODE_DNS_PATH)

  # Updates the NODE_DSN record on file with the new IP.
  echo "Updating IP address for $NODE_DNS_RECORD"

  aws --cli-connect-timeout 300 route53 change-resource-record-sets \
    --hosted-zone-id "${zone_id}" \
    --change-batch '{"Changes": [{"Action": "UPSERT","ResourceRecordSet": {"Name": "'"$NODE_DNS_RECORD"'","Type": "A","TTL": 60,"ResourceRecords": [{"Value": "'"$LOCAL_IPv4"'"}]}}]}'

  hostnamectl set-hostname "$NODE_DNS_RECORD"
  echo "DNS record for $NODE_DNS_RECORD has been updated"
else
  # TODO this will create a new DNS record if the VM is moved to another zone for any reason.
  # TODO We need a mechanism to check which DNS record does not respond and update the non responding record
  echo "$NODE_DNS_PATH does not exist. New DNS record will be created."

  while true; do
    # Concatenate "node" with the extracted number
    NODE_NAME="node-$NODE_NUMBER"

    # Check if the Route 53 record exists for the node name
    DNS_RECORD_TAKEN=$(aws route53 list-resource-record-sets --hosted-zone-id ${zone_id} --query "ResourceRecordSets[?contains(Name, '$NODE_NAME')]" --output text)

    if [ "$DNS_RECORD_TAKEN" ]; then
      echo "Record $NODE_NAME is taken in hosted zone ${zone_id}"
      # Increment node number for the next iteration
      NODE_NUMBER=$((NODE_NUMBER + 1))
    else
      echo "Record $NODE_NAME does not exist in hosted zone ${zone_id}"
      # Forms the full DNS address for the current node
      NODE_DNS_RECORD="$NODE_NAME.${zone_dns_name}"

      # Attempt to create the DNS record
      if aws --cli-connect-timeout 300 route53 change-resource-record-sets \
        --hosted-zone-id "${zone_id}" \
        --change-batch '{"Changes": [{"Action": "CREATE","ResourceRecordSet": {"Name": "'"$NODE_DNS_RECORD"'","Type": "A","TTL": 60,"ResourceRecords": [{"Value": "'"$LOCAL_IPv4"'"}]}}]}' &>/dev/null; then
        echo "DNS record for $NODE_DNS_RECORD has been created"
        hostnamectl set-hostname "$NODE_DNS_RECORD"
        echo "$NODE_DNS_RECORD" >/var/opt/graphdb/node_dns
        break # Exit loop when non-existing node name is found
      else
        echo "Creating DNS record failed for $NODE_NAME, retrying with next available name"
        # Retry with the next node number
        NODE_NUMBER=$((NODE_NUMBER + 1))
      fi
    fi
  done
fi

# Updating the EC2 name tag
aws ec2 create-tags --resources "$INSTANCE_ID" --tags "Key=Name,Value=${name}:$NODE_DNS_RECORD"
