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
IMDS_TOKEN=$(curl -Ss -H "X-aws-ec2-metadata-token-ttl-seconds: 6000" -XPUT 169.254.169.254/latest/api/token)
INSTANCE_ID=$(curl -Ss -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" 169.254.169.254/latest/meta-data/instance-id)
AVAILABILITY_ZONE=$(curl -Ss -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" 169.254.169.254/latest/meta-data/placement/availability-zone)
VOLUME_ID=""
AVAILABLE_VOLUMES=()

# Search for an available EBS volume to attach to the instance. Wait one minute for a volume to become available,
# if no volume is found - create new one, attach, format and mount the volume.
for i in $(seq 1 6); do
  VOLUME_ID=$(
    aws --cli-connect-timeout 300 ec2 describe-volumes \
      --filters "Name=status,Values=available" "Name=availability-zone,Values=$AVAILABILITY_ZONE" "Name=tag:Name,Values=${name}-graphdb-data" \
      --query "Volumes[*].{ID:VolumeId}" \
      --output text | \
      sed '/^$/d'
  )

  if [ -z "$${VOLUME_ID:-}" ]; then
    echo 'EBS volume not yet available'
    sleep 10
  else
    break
  fi
done

# Transforms the returned result to an AVAILABLE_VOLUMES
if [ -n "$VOLUME_ID" ]; then
  # Loop through each element in VOLUME_ID and add it to the AVAILABLE_VOLUMES
  while read -r element; do
    AVAILABLE_VOLUMES+=("$element")
  done <<< "$VOLUME_ID"
  echo "Found volumes: $${AVAILABLE_VOLUMES[@]}"
else
  echo "No volumes found"
fi

# Function which creates a volume
create_volume() {
  echo "Creating new volume"
  VOLUME_ID=$(
    aws --cli-connect-timeout 300 ec2 create-volume \
      --availability-zone "$AVAILABILITY_ZONE" \
      --encrypted \
      --kms-key-id "${ebs_kms_key_arn}" \
      --volume-type "${ebs_volume_type}" \
      --size "${ebs_volume_size}" \
      --iops "${ebs_volume_iops}" \
      --throughput "${ebs_volume_throughput}" \
      --tag-specifications "ResourceType=volume,Tags=[{Key=Name,Value=${name}-graphdb-data}]" | \
      jq -r .VolumeId
  )
  # Transforms the returned result to an AVAILABLE_VOLUMES
  while read -r element; do
    AVAILABLE_VOLUMES+=("$element")
  done <<< "$VOLUME_ID"

  # wait for the volume to be available
  aws --cli-connect-timeout 300 ec2 wait volume-available --volume-ids "$VOLUME_ID"
  echo "Successfully created volume: $VOLUME_ID"
}

attach_volumes() {
  local volume total_volumes
  total_volumes=$${#AVAILABLE_VOLUMES[@]}
  for ((index = 0; index < total_volumes; index++)); do
    volume=$${AVAILABLE_VOLUMES[index]}
    echo "Trying to attach volume: $volume"

    if aws --cli-connect-timeout 300 ec2 attach-volume \
      --volume-id "$volume" \
      --instance-id "$INSTANCE_ID" \
      --device "${device_name}"; then
      echo "Volume $volume attached successfully"
      break
    else
      echo "Failed to attach volume $volume"
      echo "Will try again with the next volume"

      # Check if this is the last available volume
      if ((index == total_volumes - 1)); then
        echo "Attempting to create a new volume..."
        # Resetting the AVAILABLE_VOLUMES
        AVAILABLE_VOLUMES=()
        create_volume
        attach_volumes # Retry attaching volumes including the newly created one
        break
      fi
    fi
  done
}

if [[ -z "$${AVAILABLE_VOLUMES[@]}" ]]; then
  create_volume
fi

attach_volumes

# Handle the EBS volume used for the GraphDB data directory.
# beware, here be dragons...
# read these articles:
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html
# https://github.com/oogali/ebs-automatic-nvme-mapping/blob/master/README.md

# this variable comes from terraform, and it's what we specified in the launch template as the device mapping for the ebs.
# because this might be attached under a different name, we'll need to search for it.
device_mapping_full="${device_name}"
device_mapping_short="$(echo $device_mapping_full | cut -d'/' -f3)"

graphdb_device=""

# The device might not be available immediately, wait a while
for i in $(seq 1 12); do
  for volume in $(find /dev | grep -i 'nvme[0-21]n1$'); do
    # Extract the specified device from the vendor-specific data.
    # Read https://github.com/oogali/ebs-automatic-nvme-mapping/blob/master/README.md, for more information.
    real_device=$(nvme id-ctrl --raw-binary $volume | cut -c3073-3104 | tr -s ' ' | sed 's/ $//g')
    if [ "$device_mapping_full" = "$real_device" ] || [ "$device_mapping_short" = "$real_device" ]; then
      graphdb_device="$volume"
      echo "Device found: $graphdb_device"
      break
    fi
  done

  if [ -n "$graphdb_device" ]; then
    break
  fi
  echo "Device not available, retrying ..."
  sleep 5
done

# Create a file system if there isn't any.
if [ "$graphdb_device: data" = "$(file -s $graphdb_device)" ]; then
  echo "Creating file system for $graphdb_device"
  mkfs -t ext4 $graphdb_device
fi

disk_mount_point="/var/opt/graphdb"

# Check if the disk is already mounted.
if ! mount | grep -q "$graphdb_device"; then
  echo "The disk at $graphdb_device is not mounted."

  # Create the mount point if it doesn't exist.
  if [ ! -d "$disk_mount_point" ]; then
    mkdir -p "$disk_mount_point"
  fi

  # Add an entry to the fstab file to automatically mount the disk.
  if ! grep -q "$graphdb_device" /etc/fstab; then
    echo "$graphdb_device $disk_mount_point ext4 defaults 0 2" >> /etc/fstab
  fi

  # Mount the disk.
  mount "$disk_mount_point"
  echo "The disk at $graphdb_device is now mounted at $disk_mount_point."
else
  echo "The disk at $graphdb_device is already mounted."
fi

echo "Creating data folders"
# Ensure data folders exist.
mkdir -p $disk_mount_point/node $disk_mount_point/cluster-proxy

# This is required due to ownership being reverted after the disc attachment.
chown -R graphdb:graphdb $disk_mount_point
