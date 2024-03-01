#!/usr/bin/env bash

set -euo pipefail

echo "###################################"
echo "#    Overriding Linux Settings    #"
echo "###################################"

# https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#connection-idle-timeout
echo 'net.ipv4.tcp_keepalive_time = 120' | tee -a /etc/sysctl.conf
echo 'fs.file-max = 262144' | tee -a /etc/sysctl.conf

sysctl -p
