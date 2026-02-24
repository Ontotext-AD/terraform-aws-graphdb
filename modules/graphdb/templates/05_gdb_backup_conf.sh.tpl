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
    echo "Failed to get M2M access token" >&2
    return 1
  fi

  echo "$ACCESS_TOKEN"
}

ACCESS_TOKEN=$(get_m2m_access_token)
NODE_STATE="$(curl --silent -H "Authorization: Bearer $ACCESS_TOKEN" http://localhost:7201/rest/cluster/node/status | jq -r .nodeState)"

function trigger_backup {
  local backup_name="$(date +'%Y-%m-%d_%H-%M-%S').tar"
  current_time=$(date +"%T %Y-%m-%d")
  start_time=$(date +%s)
  echo "Creating backup $backup_name at $start_time"

  # Refresh token for backup request
  ACCESS_TOKEN=$(get_m2m_access_token)

  curl \
      -vvv --fail \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      --url localhost:7201/rest/recovery/cloud-backup \
      --header 'Content-Type: multipart/form-data' \
      --header 'Accept: application/json' \
      --form "params=$(cat <<-DATA
  {
        "backupSystemData": true,
        "bucketUri": "s3:///${backup_bucket_name}/$backup_name?region=${region}"
  }
DATA
  )"
}

function rotate_backups {
  echo "Rotating backups - permanently deleting old versions"
  versions_json=$(aws --cli-connect-timeout 300 s3api list-object-versions --bucket ${backup_bucket_name})
  version_count=$(echo "$versions_json" | jq '[.Versions[]] | length')
  delete_count=$((version_count - ${backup_retention_count} - 1))

  for i in $(seq 0 $delete_count); do
    key=$(echo "$versions_json" | jq -r ".Versions[$i].Key")
    version_id=$(echo "$versions_json" | jq -r ".Versions[$i].VersionId")

    echo "Deleting: $key (version: $version_id)"
    aws --cli-connect-timeout 300 s3api delete-object --bucket ${backup_bucket_name} --key "$key" --version-id "$version_id"
  done

  # Also clean up delete markers if any exist
  delete_markers=$(echo "$versions_json" | jq -c '.DeleteMarkers[]?')
  for dm in $delete_markers; do
    dm_key=$(echo "$dm" | jq -r .Key)
    dm_version_id=$(echo "$dm" | jq -r .VersionId)

    echo "Deleting delete marker: $dm_key (version: $dm_version_id)"
    aws --cli-connect-timeout 300 s3api delete-object --bucket ${backup_bucket_name} --key "$dm_key" --version-id "$dm_version_id"
  done
}

# Checks if GraphDB is running in cluster (M2M auth)
IS_CLUSTER=$(
  curl -s -o /dev/null \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -w "%%{http_code}" \
    http://localhost:7201/rest/monitor/cluster
)

if [ "$IS_CLUSTER" -eq 200 ]; then
  echo "GraphDB is running in a cluster."
  # Checks if the current GraphDB instance is Leader, otherwise exits.
  if [ "$NODE_STATE" != "LEADER" ]; then
    echo "Current node is not a leader, but $NODE_STATE"
    exit 0
  fi
  (trigger_backup && echo "") | tee -a /var/opt/graphdb/node/graphdb_backup.log
elif [ "$IS_CLUSTER" -ne 200 ]; then
  echo "GraphDB is not running in a cluster."
  (trigger_backup && echo "") | tee -a /var/opt/graphdb/node/graphdb_backup.log
fi

rotate_backups | tee -a /var/opt/graphdb/node/graphdb_backup.log
BACKUP_SCRIPT
%{ else ~}
  # Basic authentication
  cat <<-'BACKUP_SCRIPT' >/usr/bin/graphdb_backup
#!/bin/bash

set -euo pipefail
GRAPHDB_ADMIN_PASSWORD="$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/admin_password" --with-decryption | jq -r .Parameter.Value | base64 -d)"
NODE_STATE="$(curl --silent -u "admin:$GRAPHDB_ADMIN_PASSWORD" http://localhost:7201/rest/cluster/node/status | jq -r .nodeState)"

function trigger_backup {
  local backup_name="$(date +'%Y-%m-%d_%H-%M-%S').tar"
  current_time=$(date +"%T %Y-%m-%d")
  start_time=$(date +%s)
  echo "Creating backup $backup_name at $start_time"

  curl \
      -vvv --fail \
      --user "admin:$GRAPHDB_ADMIN_PASSWORD" \
      --url localhost:7201/rest/recovery/cloud-backup \
      --header 'Content-Type: multipart/form-data' \
      --header 'Accept: application/json' \
      --form "params=$(cat <<-DATA
  {
        "backupSystemData": true,
        "bucketUri": "s3:///${backup_bucket_name}/$backup_name?region=${region}"
  }
DATA
  )"
}

function rotate_backups {
  echo "Rotating backups - permanently deleting old versions"
  versions_json=$(aws --cli-connect-timeout 300 s3api list-object-versions --bucket ${backup_bucket_name})
  version_count=$(echo "$versions_json" | jq '[.Versions[]] | length')
  delete_count=$((version_count - ${backup_retention_count} - 1))

  for i in $(seq 0 $delete_count); do
    key=$(echo "$versions_json" | jq -r ".Versions[$i].Key")
    version_id=$(echo "$versions_json" | jq -r ".Versions[$i].VersionId")

    echo "Deleting: $key (version: $version_id)"
    aws --cli-connect-timeout 300 s3api delete-object --bucket ${backup_bucket_name} --key "$key" --version-id "$version_id"
  done

  # Also clean up delete markers if any exist
  delete_markers=$(echo "$versions_json" | jq -c '.DeleteMarkers[]?')
  for dm in $delete_markers; do
    dm_key=$(echo "$dm" | jq -r .Key)
    dm_version_id=$(echo "$dm" | jq -r .VersionId)

    echo "Deleting delete marker: $dm_key (version: $dm_version_id)"
    aws --cli-connect-timeout 300 s3api delete-object --bucket ${backup_bucket_name} --key "$dm_key" --version-id "$dm_version_id"
  done
}

# Checks if GraphDB is running in cluster (Basic auth)
IS_CLUSTER=$(
  curl -s -o /dev/null \
    -u "admin:$GRAPHDB_ADMIN_PASSWORD" \
    -w "%%{http_code}" \
    http://localhost:7201/rest/monitor/cluster
)

if [ "$IS_CLUSTER" -eq 200 ]; then
  echo "GraphDB is running in a cluster."
  # Checks if the current GraphDB instance is Leader, otherwise exits.
  if [ "$NODE_STATE" != "LEADER" ]; then
    echo "Current node is not a leader, but $NODE_STATE"
    exit 0
  fi
  (trigger_backup && echo "") | tee -a /var/opt/graphdb/node/graphdb_backup.log
elif [ "$IS_CLUSTER" -ne 200 ]; then
  echo "GraphDB is not running in a cluster."
  (trigger_backup && echo "") | tee -a /var/opt/graphdb/node/graphdb_backup.log
fi

rotate_backups | tee -a /var/opt/graphdb/node/graphdb_backup.log
BACKUP_SCRIPT
%{ endif ~}

  chmod +x /usr/bin/graphdb_backup
  echo "${backup_schedule} gdb-backup /usr/bin/graphdb_backup" >/etc/cron.d/graphdb_backup
  chmod og-rwx /etc/cron.d/graphdb_backup
  # Set ownership of aws-cli to backup user
  chown -R gdb-backup:gdb-backup /usr/local/aws-cli
  chmod -R og-rwx /usr/local/aws-cli/
  log_with_timestamp "Cron job created"
else
  log_with_timestamp "Backup module is not deployed, skipping provisioning..."
fi
