#!/usr/bin/env bash

set -euxo pipefail

until ping -c 1 google.com &> /dev/null; do
  echo "waiting for outbound connectivity"
  sleep 5
done

# Register the instance in Route 53, using the volume id for the sub-domain

subdomain="$( echo -n "$volume_id" | sed 's/^vol-//' )"
node_dns="$subdomain.${zone_dns_name}"

aws --cli-connect-timeout 300 route53 change-resource-record-sets \
  --hosted-zone-id "${zone_id}" \
  --change-batch '{"Changes": [{"Action": "UPSERT","ResourceRecordSet": {"Name": "'"$node_dns"'","Type": "A","TTL": 60,"ResourceRecords": [{"Value": "'"$local_ipv4"'"}]}}]}'

hostnamectl set-hostname "$node_dns"

echo "Instance registered in Route 53 with DNS name: $node_dns"
