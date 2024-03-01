#!/usr/bin/env bash

set -euo pipefail

echo "#######################################"
echo "#   GraphDB configuration overrides   #"
echo "#######################################"

aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/license" --with-decryption | \
  jq -r .Parameter.Value | \
  base64 -d > /etc/graphdb/graphdb.license

GRAPHDB_CLUSTER_TOKEN="$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/cluster_token" --with-decryption | jq -r .Parameter.Value)"
NODE_DNS=$(cat /tmp/node_dns)

cat << EOF > /etc/graphdb/graphdb.properties
graphdb.auth.token.secret=$GRAPHDB_CLUSTER_TOKEN
graphdb.connector.port=7201
graphdb.external-url=http://$${NODE_DNS}:7201/
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

echo "Completed applying overrides"
