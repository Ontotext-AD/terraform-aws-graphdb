#!/usr/bin/env bash

# This script performs the following actions:
# * Checks if an instance refresh is in progress for the specified Auto Scaling Group (ASG).
# * If an instance refresh is in progress, it waits for the EC2 instance status check to pass.
# * Determines whether the current instance was created in response to the instance refresh.
# * If the instance was created in response to the instance refresh, it waits for an available volume in the current availability zone.
# * If no instance refresh is in progress, or if the instance was not created in response to the refresh, it proceeds with the next script.

set -o errexit
set -o nounset
set -o pipefail

# Imports helper functions
source /var/lib/cloud/instance/scripts/part-002

echo "#####################################################"
echo "#    Please be patient, these scripts take time     #"
echo "#####################################################"

# This handles instance refreshing where new and old nodes are both present.
# Waiting until the ASG nodes are equal to the expected node count and proceeding with the provisioning afterwards.
IMDS_TOKEN=$(curl -Ss -H "X-aws-ec2-metadata-token-ttl-seconds: 6000" -XPUT 169.254.169.254/latest/api/token)
AZ=$(curl -Ss -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" 169.254.169.254/latest/meta-data/placement/availability-zone)
ASG_NAME=${name}

instance_refresh_status=$(aws autoscaling describe-instance-refreshes --auto-scaling-group-name "$ASG_NAME" --query 'InstanceRefreshes[?Status==`InProgress`]' --output json)

if [ "$instance_refresh_status" != "[]" ]; then
  log_with_timestamp "An instance refresh is currently in progress for the ASG: $ASG_NAME"
  echo "$instance_refresh_status" | jq '.'

  IMDS_TOKEN=$(curl -Ss -H "X-aws-ec2-metadata-token-ttl-seconds: 6000" -XPUT 169.254.169.254/latest/api/token)
  INSTANCE_ID=$(curl -Ss -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" 169.254.169.254/latest/meta-data/instance-id)

  log_with_timestamp "Waiting for default EC2 status check to pass for instance $INSTANCE_ID..."

  # Loop until the default status check passes
  while true; do
    # Get the status of the default status checks for the instance
    instance_status=$(aws ec2 describe-instance-status --instance-ids $INSTANCE_ID --query 'InstanceStatuses[0].InstanceStatus.Status' --output text)
    system_status=$(aws ec2 describe-instance-status --instance-ids $INSTANCE_ID --query 'InstanceStatuses[0].SystemStatus.Status' --output text)

    if [[ "$instance_status" == "ok" && $system_status == "ok" ]]; then
      log_with_timestamp "Default EC2 status check passed for instance $INSTANCE_ID."
      break
    fi

    # Sleep for a while before checking again
    sleep 5
  done

  # Determines whether or not the current instance was created in response to an instance refresh
  matching_activities=$(aws autoscaling describe-scaling-activities --auto-scaling-group-name "$ASG_NAME" \
    --query "Activities[?contains(Description, '$INSTANCE_ID') && contains(Cause, 'in response to an instance refresh')]" --output json)

  # Find out if the current instance was created in response to an instance refresh
  if [ "$matching_activities" != "[]" ]; then
    log_with_timestamp "Current instance was created in response to instance refresh:"
    echo "$matching_activities" | jq '.'

    log_with_timestamp "Waiting for an available volume in $AZ"

    TIMEOUT=600 # Timeout in seconds (10 minutes)
    ELAPSED=0

    while [ $ELAPSED -lt $TIMEOUT ]; do
      # Get the list of volumes in the current availability zone
      available_volumes=$(aws ec2 describe-volumes --filters Name=availability-zone,Values=$AZ Name=status,Values=available Name=volume-type,Values=gp3 --query "Volumes[*].VolumeId" --output text)
      # Check if any volumes are available
      if [ -n "$available_volumes" ]; then
        log_with_timestamp "Found an available volume in $AZ."
        log_with_timestamp "Found volumes: $available_volumes"

        # Verify the volume is still available 3 times over 10 seconds (Handles instance_refresh VMs spawned in another AZ)
        checks_passed=0
        for i in {1..3}; do
          sleep 10
          still_available=$(aws ec2 describe-volumes --volume-ids $available_volumes --query "Volumes[?State=='available'].VolumeId" --output text)
          if [ -n "$still_available" ]; then
            checks_passed=$((checks_passed + 1))
          else
            checks_passed=0
            break
          fi
        done

        if [ $checks_passed -eq 3 ]; then
          log_with_timestamp "Confirmed the volume is still available after 30 seconds."
          break
        else
          log_with_timestamp "Volume $available_volumes was no longer available upon re-check. Continuing to wait..."
        fi
      fi

      sleep 5
      ELAPSED=$((ELAPSED + 5))
    done

    if [ $ELAPSED -ge $TIMEOUT ]; then
      log_with_timestamp "Timeout reached while waiting for an available volume in $AZ. Exiting..."
      exit 1
    fi

  else
    log_with_timestamp "Current instance was not created in response to instance refresh. Proceeding with the volume provisioning."
  fi
else
  log_with_timestamp "No instance refresh is currently in progress for the ASG: $ASG_NAME"
fi
