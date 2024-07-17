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
NODE_DNS_RECORD=$(cat /var/opt/graphdb/node_dns)
PROTOCOL=${external_address_protocol}
# Get and store the GraphDB license
aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/license" --with-decryption | \
  jq -r .Parameter.Value | \
  base64 -d > /etc/graphdb/graphdb.license

# Get the cluster token
GRAPHDB_CLUSTER_TOKEN="$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/cluster_token" --with-decryption | jq -r .Parameter.Value | base64 -d)"
# Get the NODE_DNS_RECORD value from the previous script
SSM_PARAMETERS=$(aws ssm describe-parameters --cli-connect-timeout 300 --region ${region} --query "Parameters[?starts_with(Name, '/${name}/graphdb/')].Name" --output text)
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
  cat << EOF > /etc/graphdb/graphdb.properties
graphdb.auth.token.secret=$GRAPHDB_CLUSTER_TOKEN
graphdb.connector.port=7201
graphdb.external-url=$${PROTOCOL}://$${NODE_DNS_RECORD}:7201
graphdb.rpc.address=$${NODE_DNS_RECORD}:7301
EOF

  cat << EOF > /etc/graphdb-cluster-proxy/graphdb.properties
graphdb.auth.token.secret=$GRAPHDB_CLUSTER_TOKEN
graphdb.connector.port=7200
graphdb.external-url=http://$${LB_DNS_RECORD}
graphdb.vhosts=http://$${LB_DNS_RECORD},http://$${NODE_DNS_RECORD}:7200
graphdb.rpc.address=$${NODE_DNS_RECORD}:7300
graphdb.proxy.hosts=$${NODE_DNS_RECORD}:7301
EOF
fi

mkdir -p /etc/systemd/system/graphdb.service.d/

log_with_timestamp "Calculating 85 percent of total memory"
# Get total memory in kilobytes
TOTAL_MEMORY_KB=$(grep -i "MemTotal" /proc/meminfo | awk '{print $2}')
# Convert total memory to gigabytes
TOTAL_MEMORY_GB=$(echo "scale=2; $TOTAL_MEMORY_KB / 1024 / 1024" | bc)
# Calculate 85% of total VM memory
JVM_MAX_MEMORY=$(echo "$TOTAL_MEMORY_GB * 0.85" | bc | cut -d'.' -f1)

cat << EOF > /etc/systemd/system/graphdb.service.d/overrides.conf
[Service]
Environment="GDB_HEAP_SIZE=$${JVM_MAX_MEMORY}g"
EOF

# Appends configuration overrides to graphdb.properties
if [[ $SSM_PARAMETERS == *"/${name}/graphdb/graphdb_properties"* ]]; then
  aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/graphdb_properties" --with-decryption | jq -r .Parameter.Value | \
    base64 -d >> /etc/graphdb/graphdb.properties
fi

# Appends environment overrides to GDB_JAVA_OPTS
if [[ $SSM_PARAMETERS == *"/${name}/graphdb/graphdb_java_options"* ]]; then
  extra_graphdb_java_options="$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/graphdb_java_options" --with-decryption | jq -r .Parameter.Value)"
  (
    source /etc/graphdb/graphdb.env
    echo "GDB_JAVA_OPTS=\"$GDB_JAVA_OPTS $extra_graphdb_java_options\"" >> /etc/graphdb/graphdb.env
  )
fi

log_with_timestamp "Completed applying overrides"
