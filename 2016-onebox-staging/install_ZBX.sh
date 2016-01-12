#!/bin/bash

IP="211.224.204.250/25"
GW="211.224.204.129"
_HOSTNAME="zabbix"

ifconfig eth1 $IP
ip route del default
ip route add default via $GW

apt-get install -y git
mkdir -p /root/workspace
cd /root/workspace
git clone https://github.com/ngkim/stack_ops.git
cd /root/workspace/stack_ops/iptables
./apply-iptables.sh

echo $_HOSTNAME > /etc/hostname
hostname $_HOSTNAME
