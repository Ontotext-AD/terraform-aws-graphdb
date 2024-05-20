#!/usr/bin/env bash

# This script performs the following actions:
# * Create a GraphDB backup script at /usr/bin/graphdb_backup.
# * Make the backup script executable.
# * Configure a cron job for GraphDB backup with the specified schedule.

set -o errexit
set -o nounset
set -o pipefail

# Function to print messages with timestamps
log_with_timestamp() {
  echo "$(date '+%Y-%m-%d %H:%M:%S'): $1"
}

echo "#################################################"
echo "#    Configuring the GraphDB backup cron job    #"
echo "#################################################"

if [ ${deploy_backup} == "true" ]; then
  cat <<-EOF >/usr/bin/graphdb_backup
#!/bin/bash

set -euxo pipefail

GRAPHDB_ADMIN_PASSWORD="\$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/admin_password" --with-decryption | jq -r .Parameter.Value | base64 -d)"
NODE_STATE="\$(curl --silent --fail --user "admin:\$GRAPHDB_ADMIN_PASSWORD" localhost:7201/rest/cluster/node/status | jq -r .nodeState)"

if [ "\$NODE_STATE" != "LEADER" ]; then
  echo "current node is not a leader, but \$NODE_STATE"
  exit 0
fi

function trigger_backup {
  local backup_name="\$(date +'%Y-%m-%d_%H-%M-%S').tar"

  curl \
    -vvv --fail \
    --user "admin:\$GRAPHDB_ADMIN_PASSWORD" \
    --url localhost:7201/rest/recovery/cloud-backup \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --data-binary @- <<-DATA
    {
      "backupOptions": { "backupSystemData": true },
      "bucketUri": "s3:///${backup_bucket_name}/\$backup_name?region=${region}"
    }
DATA
}

function rotate_backups {
  all_files="\$(aws --cli-connect-timeout 300 s3api list-objects --bucket ${backup_bucket_name} --query 'Contents' | jq .)"
  count="\$(echo \$all_files | jq length)"
  delete_count="\$((count - ${backup_retention_count} - 1))"

  for i in \$(seq 0 \$delete_count); do
    key="\$(echo \$all_files | jq -r .[\$i].Key)"

    aws --cli-connect-timeout 300 s3 rm s3://${backup_bucket_name}/\$key
  done
}

if ! trigger_backup; then
  echo "failed to create backup"
  exit 1
fi

rotate_backups

EOF

  chmod +x /usr/bin/graphdb_backup
  log_with_timestamp "${backup_schedule} graphdb /usr/bin/graphdb_backup" >/etc/cron.d/graphdb_backup

  log_with_timestamp "Cron job created"
else
  log_with_timestamp "Backup module is not deployed, skipping provisioning..."
fi
