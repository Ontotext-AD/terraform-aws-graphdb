#!/usr/bin/env bash

# This script performs the following actions:
# * Set CloudWatch configurations: Retrieves GraphDB admin password from AWS SSM and updates CloudWatch and Prometheus configurations.
# * Start CloudWatch agent: Initiates the CloudWatch agent, fetches configurations, and starts the agent.

set -o errexit
set -o nounset
set -o pipefail

# Imports helper functions
source /var/lib/cloud/instance/scripts/part-002

echo "#################################"
echo "#    Cloudwatch Provisioning    #"
echo "#################################"

usermod -aG adm cwagent

# Appends configuration overrides to graphdb.properties
if [ ${deploy_monitoring} == "true" ]; then
  GRAPHDB_ADMIN_PASSWORD=$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/admin_password" --with-decryption --query "Parameter.Value" --output text | base64 -d)
  # Parse the CW Agent Config from SSM Parameter store and put it in file
  CWAGENT_CONFIG=$(aws ssm get-parameter --name "/${name}/graphdb/CWAgent/Config" --query "Parameter.Value" --with-decryption --output text)
  echo "$CWAGENT_CONFIG" >/etc/graphdb/cloudwatch-agent-config.json

  tmp=$(mktemp)
  jq '.logs.metrics_collected.prometheus.log_group_name = "${name}"' /etc/graphdb/cloudwatch-agent-config.json >"$tmp" && mv "$tmp" /etc/graphdb/cloudwatch-agent-config.json
  jq '.logs.metrics_collected.prometheus.emf_processor.metric_namespace = "${name}"' /etc/graphdb/cloudwatch-agent-config.json >"$tmp" && mv "$tmp" /etc/graphdb/cloudwatch-agent-config.json
  cat /etc/prometheus/prometheus.yaml | yq '.scrape_configs[].static_configs[].targets = ["localhost:7201"]' >"$tmp" && mv "$tmp" /etc/prometheus/prometheus.yaml
  cat /etc/prometheus/prometheus.yaml | yq '.scrape_configs[].basic_auth.username = "admin"' | yq ".scrape_configs[].basic_auth.password = \"$${GRAPHDB_ADMIN_PASSWORD}\"" >"$tmp" && mv "$tmp" /etc/prometheus/prometheus.yaml

  # Make config file readable only by cwagent user
  chmod og-rw /etc/prometheus/prometheus.yaml
  chown -R cwagent:cwagent /etc/prometheus
  amazon-cloudwatch-agent-ctl -a start
  amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/etc/graphdb/cloudwatch-agent-config.json

else
  log_with_timestamp "Monitoring module was not deployed, skipping provisioning..."
fi
