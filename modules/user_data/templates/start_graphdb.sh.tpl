#!/usr/bin/env bash

set -euxo pipefail

until ping -c 1 google.com &> /dev/null; do
  echo "waiting for outbound connectivity"
  sleep 5
done

systemctl stop graphdb

# Set common variables used throughout the script.
imds_token=$( curl -Ss -H "X-aws-ec2-metadata-token-ttl-seconds: 300" -XPUT 169.254.169.254/latest/api/token )
local_ipv4=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/local-ipv4 )
instance_id=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/instance-id )
availability_zone=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/placement/availability-zone )
volume_id=""

# Defining variables by interpolating Terraform variables

region="${region}"
name="${name}"
device_name="${device_name}"

backup_schedule="${backup_schedule}"
backup_retention_count="${backup_retention_count}"
backup_bucket_name="${backup_bucket_name}"

ebs_volume_type="${ebs_volume_type}"
ebs_volume_size="${ebs_volume_size}"
ebs_volume_iops="${ebs_volume_iops}"
ebs_volume_throughput="${ebs_volume_throughput}"
ebs_kms_key_arn="${ebs_kms_key_arn}"

zone_dns_name="${zone_dns_name}"
zone_id="${zone_id}"

jvm_max_memory="${jvm_max_memory}"
resource_name_prefix="${resource_name_prefix}"

GRAPHDB_CONNECTOR_PORT=""

# Search for an available EBS volume to attach to the instance. If no volume is found - create new one, attach, format and mount the volume.
source /opt/helper-scripts/ebs_volume.sh

# Register the instance in Route 53, using the volume id for the sub-domain
source /opt/helper-scripts/register_route53.sh

# Configure the GraphDB backup cron job
source /opt/helper-scripts/create_backup.sh

# Configure GraphDB

aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/license" --with-decryption | \
  jq -r .Parameter.Value | \
  base64 -d > /etc/graphdb/graphdb.license

graphdb_cluster_token="$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/cluster_token" --with-decryption | jq -r .Parameter.Value)"

cat << EOF > /etc/graphdb/graphdb.properties
graphdb.auth.token.secret=$graphdb_cluster_token
graphdb.connector.port=7201
graphdb.external-url=http://$${node_dns}:7201/
graphdb.rpc.address=$${node_dns}:7301
EOF

load_balancer_dns=$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/lb_dns_name" | jq -r .Parameter.Value)

cat << EOF > /etc/graphdb-cluster-proxy/graphdb.properties
graphdb.auth.token.secret=$graphdb_cluster_token
graphdb.connector.port=7200
graphdb.external-url=http://$${load_balancer_dns}
graphdb.vhosts=http://$${load_balancer_dns},http://$${node_dns}:7200
graphdb.rpc.address=$${node_dns}:7300
graphdb.proxy.hosts=$${node_dns}:7301
EOF

mkdir -p /etc/systemd/system/graphdb.service.d/

cat << EOF > /etc/systemd/system/graphdb.service.d/overrides.conf
[Service]
Environment="GDB_HEAP_SIZE=${jvm_max_memory}g"
EOF

# https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#connection-idle-timeout
echo 'net.ipv4.tcp_keepalive_time = 120' | tee -a /etc/sysctl.conf
echo 'fs.file-max = 262144' | tee -a /etc/sysctl.conf

sysctl -p

tmp=$(mktemp)
jq '.logs.metrics_collected.prometheus.log_group_name = "${resource_name_prefix}-graphdb"' /etc/graphdb/cloudwatch-agent-config.json > "$tmp" && mv "$tmp" /etc/graphdb/cloudwatch-agent-config.json
jq '.logs.metrics_collected.prometheus.emf_processor.metric_namespace = "${resource_name_prefix}-graphdb"' /etc/graphdb/cloudwatch-agent-config.json > "$tmp" && mv "$tmp" /etc/graphdb/cloudwatch-agent-config.json
cat /etc/prometheus/prometheus.yaml | yq '.scrape_configs[].static_configs[].targets = ["localhost:7201"]' > "$tmp" && mv "$tmp" /etc/prometheus/prometheus.yaml

amazon-cloudwatch-agent-ctl -a start
amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/etc/graphdb/cloudwatch-agent-config.json

# the proxy service is set up in the AMI but not enabled there, so we enable and start it
systemctl daemon-reload
systemctl start graphdb
systemctl enable graphdb-cluster-proxy.service
systemctl start graphdb-cluster-proxy.service
