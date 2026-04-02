#!/usr/bin/env bash

# This script performs the following actions:
# * Create a GraphDB backup script at /usr/bin/graphdb_backup.
# * Make the backup script executable.
# * Configure a cron job for GraphDB backup with the specified schedule.

set -o errexit
set -o nounset
set -o pipefail

# Imports helper functions
source /var/lib/cloud/instance/scripts/part-002

echo "#################################################"
echo "#    Configuring the GraphDB backup cron job    #"
echo "#################################################"

if [ ${deploy_backup} == "true" ]; then
  # Create the backup user. ID : 1010
  echo "Creating the backup user"
  useradd -r -M -s /usr/sbin/nologin gdb-backup
  # Initialize the log file so that we are safe from potential attacks
  [[ -f /var/opt/graphdb/node/graphdb_backup.log ]] && rm /var/opt/graphdb/node/graphdb_backup.log
  touch /var/opt/graphdb/node/graphdb_backup.log
  chown gdb-backup:gdb-backup /var/opt/graphdb/node/graphdb_backup.log
  chmod og-rw /var/opt/graphdb/node/graphdb_backup.log

%{ if m2m_enabled == "true" ~}
  # M2M authentication enabled - write backup script with bearer token auth
  cat <<-'BACKUP_SCRIPT' >/usr/bin/graphdb_backup
#!/bin/bash

set -euo pipefail

exec >> /var/opt/graphdb/node/graphdb_backup.log 2>&1

log_with_timestamp() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

M2M_CLIENT_ID="${m2m_client_id}"
M2M_SCOPE="${m2m_scope}"
OPENID_TENANT_ID="${openid_tenant_id}"

# Function to get M2M access token
get_m2m_access_token() {
  local M2M_CLIENT_SECRET
  M2M_CLIENT_SECRET=$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/m2m_client_secret" --with-decryption --query "Parameter.Value" --output text | base64 -d)

  local TOKEN_ENDPOINT="https://login.microsoftonline.com/$OPENID_TENANT_ID/oauth2/v2.0/token"

  local TOKEN_RESPONSE
  TOKEN_RESPONSE=$(curl -s -X POST "$TOKEN_ENDPOINT" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=$M2M_CLIENT_ID" \
    -d "client_secret=$M2M_CLIENT_SECRET" \
    -d "scope=$M2M_SCOPE" \
    -d "grant_type=client_credentials")

  local ACCESS_TOKEN
  ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

  if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
    log_with_timestamp "Failed to get M2M access token"
    return 1
  fi

  echo "$ACCESS_TOKEN"
}

if ! ACCESS_TOKEN=$(get_m2m_access_token); then
  log_with_timestamp "ERROR: Failed to obtain M2M access token. Exiting."
  exit 1
fi

BACKUP_NAME=""

function trigger_backup {
  BACKUP_NAME="$(date +'%Y-%m-%d_%H-%M-%S').tar"
  local start_time=$(date +%s)
  log_with_timestamp "Creating backup $BACKUP_NAME"

  # Refresh token for backup request
  if ! ACCESS_TOKEN=$(get_m2m_access_token); then
    log_with_timestamp "ERROR: Failed to refresh M2M access token. Exiting."
    exit 1
  fi

  if ! curl \
      -vvv --fail \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      --url localhost:7201/rest/recovery/cloud-backup \
      --header 'Content-Type: multipart/form-data' \
      --header 'Accept: application/json' \
      --form "params=$(cat <<-DATA
  {
        "backupSystemData": true,
        "bucketUri": "s3:///${backup_bucket_name}/$BACKUP_NAME?region=${region}"
  }
DATA
  )"; then
    log_with_timestamp "ERROR: Backup $BACKUP_NAME failed. Exiting."
    exit 1
  fi

  local end_time=$(date +%s)
  log_with_timestamp "Backup $BACKUP_NAME completed in $((end_time - start_time)) seconds"
}

# Checks if GraphDB is running in cluster (M2M auth)
IS_CLUSTER=$(
  curl -s -o /dev/null \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -w "%%{http_code}" \
    http://localhost:7201/rest/monitor/cluster
)

if [ "$IS_CLUSTER" -eq 200 ]; then
  log_with_timestamp "GraphDB is running in a cluster."
  # Checks if the current GraphDB instance is Leader, otherwise exits.
  NODE_STATE="$(curl --silent -H "Authorization: Bearer $ACCESS_TOKEN" http://localhost:7201/rest/cluster/node/status | jq -r .nodeState)"
  if [ "$NODE_STATE" != "LEADER" ]; then
    log_with_timestamp "Current node is not a leader, but $NODE_STATE"
    exit 0
  fi
  trigger_backup
else
  log_with_timestamp "GraphDB is not running in a cluster."
  trigger_backup
fi
BACKUP_SCRIPT
%{ else ~}
  # Basic authentication
  cat <<-'BACKUP_SCRIPT' >/usr/bin/graphdb_backup
#!/bin/bash

set -euo pipefail

exec >> /var/opt/graphdb/node/graphdb_backup.log 2>&1

log_with_timestamp() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

GRAPHDB_ADMIN_PASSWORD="$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/admin_password" --with-decryption | jq -r .Parameter.Value | base64 -d)"

BACKUP_NAME=""

function trigger_backup {
  BACKUP_NAME="$(date +'%Y-%m-%d_%H-%M-%S').tar"
  local start_time=$(date +%s)
  log_with_timestamp "Creating backup $BACKUP_NAME"

  if ! curl \
      -vvv --fail \
      --user "admin:$GRAPHDB_ADMIN_PASSWORD" \
      --url localhost:7201/rest/recovery/cloud-backup \
      --header 'Content-Type: multipart/form-data' \
      --header 'Accept: application/json' \
      --form "params=$(cat <<-DATA
  {
        "backupSystemData": true,
        "bucketUri": "s3:///${backup_bucket_name}/$BACKUP_NAME?region=${region}"
  }
DATA
  )"; then
    log_with_timestamp "ERROR: Backup $BACKUP_NAME failed. Exiting."
    exit 1
  fi

  local end_time=$(date +%s)
  log_with_timestamp "Backup $BACKUP_NAME completed in $((end_time - start_time)) seconds"
}

# Checks if GraphDB is running in cluster (Basic auth)
IS_CLUSTER=$(
  curl -s -o /dev/null \
    -u "admin:$GRAPHDB_ADMIN_PASSWORD" \
    -w "%%{http_code}" \
    http://localhost:7201/rest/monitor/cluster
)

if [ "$IS_CLUSTER" -eq 200 ]; then
  log_with_timestamp "GraphDB is running in a cluster."
  # Checks if the current GraphDB instance is Leader, otherwise exits.
  NODE_STATE="$(curl --silent -u "admin:$GRAPHDB_ADMIN_PASSWORD" http://localhost:7201/rest/cluster/node/status | jq -r .nodeState)"
  if [ "$NODE_STATE" != "LEADER" ]; then
    log_with_timestamp "Current node is not a leader, but $NODE_STATE"
    exit 0
  fi
  trigger_backup
else
  log_with_timestamp "GraphDB is not running in a cluster."
  trigger_backup
fi
BACKUP_SCRIPT
%{ endif ~}

cat <<-'ROTATE_SCRIPT' >>/usr/bin/graphdb_backup

function rotate_backups {
  log_with_timestamp "Rotating backups: retaining the ${backup_retention_count} most recent backup(s) and deleting the rest"

  if ! all_backups=$(aws --cli-connect-timeout 300 s3api list-objects-v2 \
    --region ${region} \
    --bucket ${backup_bucket_name} \
    --query 'Contents[?ends_with(Key, `.tar`)] | sort_by(@, &Key)' \
    --output json); then
    log_with_timestamp "ERROR: Failed to access S3 bucket ${backup_bucket_name}. Exiting."
    exit 1
  fi

  if [ -z "$all_backups" ] || [ "$all_backups" = "null" ] || [ "$all_backups" = "[]" ]; then
    log_with_timestamp "No backups found in S3, skipping rotation"
    return
  fi

  backup_count=$(echo "$all_backups" | jq 'length')
  delete_count=$((backup_count - ${backup_retention_count}))

  if [ "$delete_count" -le 0 ]; then
    log_with_timestamp "Number of backups ($backup_count) is within retention limit (${backup_retention_count}), no rotation needed"
    return
  fi

  log_with_timestamp "Found $backup_count backup(s), exceeding retention limit of ${backup_retention_count} by $delete_count. Deleting $delete_count oldest backup(s)..."
  for i in $(seq 0 $((delete_count - 1))); do
    key=$(echo "$all_backups" | jq -r ".[$i].Key")
    log_with_timestamp "Deleting: $key"
    aws s3 rm "s3://${backup_bucket_name}/$key" --region ${region} > /dev/null
    log_with_timestamp "Deleted: $key"
  done
}

if [ -z "$BACKUP_NAME" ]; then
  log_with_timestamp "No backup was created, skipping rotation"
  exit 1
fi

log_with_timestamp "Verifying backup $BACKUP_NAME exists in S3 before rotating..."
if aws --cli-connect-timeout 300 s3api head-object \
    --region ${region} \
    --bucket ${backup_bucket_name} \
    --key "$BACKUP_NAME" &>/dev/null; then
  log_with_timestamp "Backup $BACKUP_NAME confirmed in S3"
  rotate_backups
else
  log_with_timestamp "Backup $BACKUP_NAME not found in S3, skipping rotation to preserve existing backups"
  exit 1
fi
ROTATE_SCRIPT

  chmod +x /usr/bin/graphdb_backup
  echo "${backup_schedule} gdb-backup /usr/bin/graphdb_backup" >/etc/cron.d/graphdb_backup
  chmod og-rwx /etc/cron.d/graphdb_backup

  # Configure log rotation for the backup log
  cat <<-'LOGROTATE' >/etc/logrotate.d/graphdb_backup
/var/opt/graphdb/node/graphdb_backup.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 0600 gdb-backup gdb-backup
}
LOGROTATE
  # Set ownership of aws-cli to backup user
  chown -R gdb-backup:gdb-backup /usr/local/aws-cli
  chmod -R og-rwx /usr/local/aws-cli/
  log_with_timestamp "Cron job created"
else
  log_with_timestamp "Backup module is not deployed, skipping provisioning..."
fi
