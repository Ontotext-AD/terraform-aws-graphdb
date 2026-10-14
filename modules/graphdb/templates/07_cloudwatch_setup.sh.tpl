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

  # Per-node log groups are created by Terraform and the instance role cannot create log groups.
  # A node whose log group does not exist ships its GraphDB log to the shared log group instead of dropping it.
  NODE_LOG_GROUP="${name}-$(hostname)"
  NODE_LOG_GROUP_STATUS="unknown"
  for i in {1..6}; do
    if NODE_LOG_GROUP_FOUND=$(aws logs describe-log-groups --region ${region} --log-group-name-prefix "$NODE_LOG_GROUP" --query "logGroups[?logGroupName=='$NODE_LOG_GROUP'].logGroupName" --output text); then
      if [ -n "$NODE_LOG_GROUP_FOUND" ]; then
        NODE_LOG_GROUP_STATUS="found"
        break
      fi
      NODE_LOG_GROUP_STATUS="missing"
    fi
    sleep 10
  done

  if [ "$NODE_LOG_GROUP_STATUS" == "missing" ]; then
    log_with_timestamp "WARNING: Log group $NODE_LOG_GROUP does not exist, shipping the GraphDB log to ${name}"
    jq '(.logs.logs_collected.files.collect_list[] | select(.log_group_name == "${name}-{local_hostname}") | .log_group_name) = "${name}"' /etc/graphdb/cloudwatch-agent-config.json >"$tmp" && mv "$tmp" /etc/graphdb/cloudwatch-agent-config.json
  elif [ "$NODE_LOG_GROUP_STATUS" == "unknown" ]; then
    log_with_timestamp "WARNING: Could not check if log group $NODE_LOG_GROUP exists, keeping the default configuration"
  fi

  # Make config file readable only by cwagent user
  chmod og-rw /etc/prometheus/prometheus.yaml
  chown -R cwagent:cwagent /etc/prometheus
  amazon-cloudwatch-agent-ctl -a start
  amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/etc/graphdb/cloudwatch-agent-config.json

else
  log_with_timestamp "Monitoring module was not deployed, skipping provisioning..."
fi
