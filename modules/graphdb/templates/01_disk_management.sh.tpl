#!/usr/bin/env bash

# This script performs the following actions:
# * Set common variables: Retrieves IMDS token, instance ID, and availability zone.
# * Search for available EBS volume: Iterates up to 6 times to find or create an EBS volume tagged for GraphDB.
# * Attach EBS volume to instance: Connects the volume to the EC2 instance using a specified device name.
# * Store volume ID: Saves the volume ID for use in another script.
# * Handle EBS volume for GraphDB data directory: Manages device mapping complexities and creates a file system if needed.
# * Mount and configure file system: Ensures the file system is mounted, configures automatic mounting, and sets proper ownership.

set -o errexit
set -o nounset
set -o pipefail

echo "###########################################"
echo "#    Creating/Attaching managed disks     #"
echo "###########################################"

# Set common variables used throughout the script.
IMDS_TOKEN=$(curl -s -H "X-aws-ec2-metadata-token-ttl-seconds: 6000" -X PUT 169.254.169.254/latest/api/token)
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" 169.254.169.254/latest/meta-data/instance-id)
AVAILABILITY_ZONE=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" 169.254.169.254/latest/meta-data/placement/availability-zone)
disk_mount_point="/var/opt/graphdb"
AVAILABLE_VOLUMES=()

# Function to create a volume
create_volume() {
  echo "Creating new volume"
  VOLUME_ID=$(aws ec2 create-volume \
    --availability-zone "$AVAILABILITY_ZONE" \
    --encrypted \
    --kms-key-id "${ebs_kms_key_arn}" \
    --volume-type "${ebs_volume_type}" \
    --size "${ebs_volume_size}" \
    --iops "${ebs_volume_iops}" \
    --throughput "${ebs_volume_throughput}" \
    --tag-specifications "ResourceType=volume,Tags=[{Key=Name,Value=${name}-graphdb-data}]" \
    --query "VolumeId" --output text)

  AVAILABLE_VOLUMES+=("$VOLUME_ID")

  # Wait for the volume to be available
  aws ec2 wait volume-available --volume-ids "$VOLUME_ID"
  echo "Successfully created volume: $VOLUME_ID"
}

# Function to attach volumes
attach_volumes() {
  for volume in "$${AVAILABLE_VOLUMES[@]}"; do
    echo "Trying to attach volume: $volume"
    if aws ec2 attach-volume --volume-id "$volume" --instance-id "$INSTANCE_ID" --device "${device_name}"; then
      echo "Volume $volume attached successfully"
      return
    else
      echo "Failed to attach volume $volume. Trying the next volume..."
    fi
  done

  echo "No available volumes to attach. Creating a new volume..."
  AVAILABLE_VOLUMES=()
  create_volume
  attach_volumes
}

# Check if the device is already mounted
if mount | grep -q "on $disk_mount_point"; then
  echo "Device is already mounted at $disk_mount_point"
else
  for _ in {1..6}; do
    VOLUME_ID=$(aws ec2 describe-volumes \
      --filters "Name=status,Values=available" "Name=availability-zone,Values=$AVAILABILITY_ZONE" "Name=tag:Name,Values=${name}-graphdb-data" \
      --query "Volumes[*].VolumeId" --output text | tr -s '\t' '\n')

    if [ -n "$VOLUME_ID" ]; then
      AVAILABLE_VOLUMES=($VOLUME_ID)
      echo "Found volumes: $${AVAILABLE_VOLUMES[*]}"
      break
    else
      echo "EBS volume not yet available. Retrying..."
      sleep 10
    fi
  done

  if [ -z "$${AVAILABLE_VOLUMES[*]}" ]; then
    create_volume
  fi
  echo "No device is mounted at $disk_mount_point"
  attach_volumes

  # Handle the EBS volume used for the GraphDB data directory.
  # beware, here be dragons...
  # read these articles:
  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html
  # https://github.com/oogali/ebs-automatic-nvme-mapping/blob/master/README.md

  # this variable comes from terraform, and it's what we specified in the launch template as the device mapping for the ebs.
  # because this might be attached under a different name, we'll need to search for it.
  device_mapping_full="${device_name}"
  device_mapping_short=$(basename "$device_mapping_full")
  graphdb_device=""

  for _ in {1..12}; do
    for volume in /dev/nvme[0-21]n1; do
      if [ -e "$volume" ]; then
        real_device=$(nvme id-ctrl --raw-binary "$volume" | cut -c3073-3104 | tr -s ' ' | sed 's/ $//')
        if [[ "$device_mapping_full" == "$real_device" || "$device_mapping_short" == "$real_device" ]]; then
          graphdb_device="$volume"
          echo "Device found: $graphdb_device"
          break 2
        fi
      fi
    done
    echo "Device not available, retrying ..."
    sleep 5
  done

  if [ "$graphdb_device: data" == "$(file -s "$graphdb_device")" ]; then
    echo "Creating file system for $graphdb_device"
    mkfs -t ext4 "$graphdb_device"
  fi

  mkdir -p "$disk_mount_point"
  if ! grep -q "$graphdb_device" /etc/fstab; then
    echo "$graphdb_device $disk_mount_point ext4 defaults 0 2" >> /etc/fstab
  fi

  mount "$disk_mount_point"
  echo "The disk at $graphdb_device is now mounted at $disk_mount_point."

  echo "Creating data folders"
  mkdir -p "$disk_mount_point/node" "$disk_mount_point/cluster-proxy"
  chown -R graphdb:graphdb "$disk_mount_point"
fi
