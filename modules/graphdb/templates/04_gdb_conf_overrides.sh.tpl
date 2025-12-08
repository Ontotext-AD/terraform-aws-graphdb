#!/usr/bin/env bash

# This script performs the following actions:
# * Retrieve GraphDB configuration parameters from AWS Systems Manager (SSM).
# * Decode and save the GraphDB license file.
# * Set GraphDB cluster token, node DNS, and other properties in the GraphDB configuration file.
# * Get the load balancer (LB) DNS name from AWS Systems Manager.
# * Configure the GraphDB Cluster Proxy properties with LB DNS and node DNS.
# * Create systemd service overrides for GraphDB, setting JVM max memory to 85% of the total memory.
# * Save the calculated JVM max memory to systemd service overrides.

set -o errexit
set -o nounset
set -o pipefail

# Imports helper functions
source /var/lib/cloud/instance/scripts/part-002

echo "#######################################"
echo "#   GraphDB configuration overrides   #"
echo "#######################################"

LB_DNS_RECORD=${graphdb_lb_dns_name}
PROTOCOL=${external_address_protocol}
# Get and store the GraphDB license
aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/license" --with-decryption | \
  jq -r .Parameter.Value | \
  base64 -d > /etc/graphdb/graphdb.license

# Get the cluster token
GRAPHDB_CLUSTER_TOKEN="$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/cluster_token" --with-decryption | jq -r .Parameter.Value | base64 -d)"
NODE_COUNT=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${name} --query "AutoScalingGroups[0].DesiredCapacity" --output text)

# graphdb.external-url.enforce.transactions: determines whether it is necessary to rewrite the Location header when no proxy is configured.
# This is required because when working with the GDB transaction endpoint it returns an erroneous URL with HTTP protocol instead of HTTPS
if [ "$NODE_COUNT" -eq 1 ]; then
  cat << EOF > /etc/graphdb/graphdb.properties
graphdb.connector.port=7201
graphdb.external-url=$${PROTOCOL}://$${LB_DNS_RECORD}
graphdb.external-url.enforce.transactions=true
EOF
else
  NODE_DNS_RECORD=$(cat /var/opt/graphdb/node_dns)

  cat << EOF > /etc/graphdb/graphdb.properties
graphdb.auth.token.secret=$GRAPHDB_CLUSTER_TOKEN
graphdb.connector.port=7201
graphdb.external-url=http://$${NODE_DNS_RECORD}:7201
graphdb.rpc.address=$${NODE_DNS_RECORD}:7301
EOF

  cat << EOF > /etc/graphdb-cluster-proxy/graphdb.properties
graphdb.auth.token.secret=$GRAPHDB_CLUSTER_TOKEN
graphdb.connector.port=7200
graphdb.external-url=$${PROTOCOL}://$${LB_DNS_RECORD}
graphdb.vhosts=$${PROTOCOL}://$${LB_DNS_RECORD},http://$${NODE_DNS_RECORD}:7200
graphdb.rpc.address=$${NODE_DNS_RECORD}:7300
graphdb.proxy.hosts=$${NODE_DNS_RECORD}:7301
EOF
fi

mkdir -p /etc/systemd/system/graphdb.service.d/

JVM_MEMORY_RATIO="${JVM_MEMORY_RATIO}"
log_with_timestamp "Calculating ${JVM_MEMORY_RATIO} percent of total memory"
# Get total memory in kilobytes
TOTAL_MEMORY_KB=$(grep -i "MemTotal" /proc/meminfo | awk '{print $2}')
# Convert total memory to gigabytes
TOTAL_MEMORY_GB=$(echo "scale=2; $TOTAL_MEMORY_KB / 1024 / 1024" | bc)
# Calculate JVM memory as PERCENT% of total VM memory
JVM_MAX_MEMORY=$(echo "scale=2; $TOTAL_MEMORY_GB * $JVM_MEMORY_RATIO / 100" | bc | cut -d'.' -f1)

cat << EOF > /etc/systemd/system/graphdb.service.d/overrides.conf
[Service]
Environment="GDB_HEAP_SIZE=$${JVM_MAX_MEMORY}g"
EOF

# Appends configuration overrides to graphdb.properties
GDB_PROPERTIES=$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/graphdb_properties" --with-decryption 2>/dev/null | jq -r .Parameter.Value | base64 -d || /bin/true)
[[ -n $GDB_PROPERTIES ]] && echo "$GDB_PROPERTIES" >> /etc/graphdb/graphdb.properties

# Appends environment overrides to GDB_JAVA_OPTS
extra_graphdb_java_options="$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/graphdb_java_options" --with-decryption 2>/dev/null | jq -r .Parameter.Value || /bin/true )"
if [[ -n $extra_graphdb_java_options  ]]; then
  if grep GDB_JAVA_OPTS /etc/graphdb/graphdb.env &>/dev/null; then
    sed -ie "s|GDB_JAVA_OPTS=\"\(.*\)\"|GDB_JAVA_OPTS=\"\1 $extra_graphdb_java_options\"|g" /etc/graphdb/graphdb.env
  else
    echo "GDB_JAVA_OPTS=$extra_graphdb_java_options" > /etc/graphdb/graphdb.env
  fi
fi

log_with_timestamp "Completed applying overrides"
