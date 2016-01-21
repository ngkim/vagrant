#!/bin/bash

IP="211.224.204.130/25"
GW="211.224.204.129"

ifconfig eth2 $IP
ip route del default
ip route add default via $GW

apt-get install -y ntp git

mkdir -p /root/workspace
cd /root/workspace
git clone https://github.com/ngkim/stack_ops.git
cd /root/workspace/stack_ops/iptables
./apply-iptables.sh

ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
service ntp restart

