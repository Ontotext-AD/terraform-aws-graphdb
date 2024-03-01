#!/usr/bin/env bash

set -euo pipefail

echo "########################"
echo "#   DNS Provisioning   #"
echo "########################"

IMDS_TOKEN=$( curl -Ss -H "X-aws-ec2-metadata-token-ttl-seconds: 6000" -XPUT 169.254.169.254/latest/api/token )
LOCAL_IPv4=$( curl -Ss -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" 169.254.169.254/latest/meta-data/local-ipv4 )
VOLUME_ID=$(cat /tmp/volume_id)

SUBDOMAIN="$( echo -n "$VOLUME_ID" | sed 's/^vol-//' )"
NODE_DNS="$SUBDOMAIN.${zone_dns_name}"

echo $NODE_DNS > /tmp/node_dns

aws --cli-connect-timeout 300 route53 change-resource-record-sets \
  --hosted-zone-id "${zone_id}" \
  --change-batch '{"Changes": [{"Action": "UPSERT","ResourceRecordSet": {"Name": "'"$NODE_DNS"'","Type": "A","TTL": 60,"ResourceRecords": [{"Value": "'"$LOCAL_IPv4"'"}]}}]}'

echo "DNS record for $NODE_DNS has been created"

hostnamectl set-hostname "$NODE_DNS"

