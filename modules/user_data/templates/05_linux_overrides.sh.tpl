#!/usr/bin/env bash

# This script performs the following actions:
# * Override Linux settings related to network load balancers.
# * Apply the changes to the system.

set -o errexit
set -o nounset
set -o pipefail

echo "###################################"
echo "#    Overriding Linux Settings    #"
echo "###################################"

# Read this article: https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#connection-idle-timeout
echo 'net.ipv4.tcp_keepalive_time = 120' | tee -a /etc/sysctl.conf
echo 'fs.file-max = 262144' | tee -a /etc/sysctl.conf

sysctl -p
