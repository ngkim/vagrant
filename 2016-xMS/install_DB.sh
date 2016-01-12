#!/bin/bash

IP="211.224.204.244/25"
GW="211.224.204.129"

ifconfig eth1 $IP
ip route del default
ip route add default via $GW

yum install git
mkdir -p /root/workspace
cd /root/workspace
git clone https://github.com/ngkim/stack_ops.git
cd /root/workspace/stack_ops/iptables
./apply-iptables.sh
