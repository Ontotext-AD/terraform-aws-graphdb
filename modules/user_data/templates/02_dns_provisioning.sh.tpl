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

IMDS_TOKEN=$( curl -Ss -H "X-aws-ec2-metadata-token-ttl-seconds: 6000" -XPUT 169.254.169.254/latest/api/token )
LOCAL_IPv4=$( curl -Ss -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" 169.254.169.254/latest/meta-data/local-ipv4 )
VOLUME_ID=$(cat /tmp/volume_id)

# Subdomain is based on the volume name.
SUBDOMAIN="$( echo -n "$VOLUME_ID" | sed 's/^vol-//' )"
NODE_DNS="$SUBDOMAIN.${zone_dns_name}"

# Storing it to be used in another script
echo $NODE_DNS > /tmp/node_dns

# Creates the DNS record
aws --cli-connect-timeout 300 route53 change-resource-record-sets \
  --hosted-zone-id "${zone_id}" \
  --change-batch '{"Changes": [{"Action": "UPSERT","ResourceRecordSet": {"Name": "'"$NODE_DNS"'","Type": "A","TTL": 60,"ResourceRecords": [{"Value": "'"$LOCAL_IPv4"'"}]}}]}'

echo "DNS record for $NODE_DNS has been created"

hostnamectl set-hostname "$NODE_DNS"

