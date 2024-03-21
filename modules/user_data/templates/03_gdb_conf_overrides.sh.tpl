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

echo "#######################################"
echo "#   GraphDB configuration overrides   #"
echo "#######################################"

# Get and store the GraphDB license
aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/license" --with-decryption | \
  jq -r .Parameter.Value | \
  base64 -d > /etc/graphdb/graphdb.license

# Get the cluster token
GRAPHDB_CLUSTER_TOKEN="$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/cluster_token" --with-decryption | jq -r .Parameter.Value | base64 -d)"
# Get the NODE_DNS value from the previous script
NODE_DNS=$(cat /tmp/node_dns)

cat << EOF > /etc/graphdb/graphdb.properties
graphdb.auth.token.secret=$GRAPHDB_CLUSTER_TOKEN
graphdb.connector.port=7201
graphdb.external-url=http://$${NODE_DNS}:7201
graphdb.rpc.address=$${NODE_DNS}:7301
EOF

LB_DNS=$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/lb_dns_name" | jq -r .Parameter.Value)

cat << EOF > /etc/graphdb-cluster-proxy/graphdb.properties
graphdb.auth.token.secret=$GRAPHDB_CLUSTER_TOKEN
graphdb.connector.port=7200
graphdb.external-url=http://$${LB_DNS}
graphdb.vhosts=http://$${LB_DNS},http://$${NODE_DNS}:7200
graphdb.rpc.address=$${NODE_DNS}:7300
graphdb.proxy.hosts=$${NODE_DNS}:7301
EOF

mkdir -p /etc/systemd/system/graphdb.service.d/

echo "Calculating 85 percent of total memory"
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

parameters=$(aws ssm describe-parameters --cli-connect-timeout 300 --region ${region} --query "Parameters[?starts_with(Name, '/${name}/graphdb/')].Name" --output text)

# Appends configuration overrides to graphdb.properties
if [[ $parameters == *"/${name}/graphdb/graphdb_properties"* ]]; then
  aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/graphdb_properties" --with-decryption | jq -r .Parameter.Value | \
    base64 -d >> /etc/graphdb/graphdb.properties
fi

# Appends environment overrides to GDB_JAVA_OPTS
if [[ $parameters == *"/${name}/graphdb/graphdb_java_options"* ]]; then
  extra_graphdb_java_options="$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/graphdb_java_options" --with-decryption | jq -r .Parameter.Value)"
  (
    source /etc/graphdb/graphdb.env
    echo "GDB_JAVA_OPTS=\"$GDB_JAVA_OPTS $extra_graphdb_java_options\"" >> /etc/graphdb/graphdb.env
  )
fi

echo "Completed applying overrides"
