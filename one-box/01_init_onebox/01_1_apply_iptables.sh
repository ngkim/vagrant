#!/bin/bash

apt-get install -y git
mkdir -p /root/workspace
cd /root/workspace
git clone https://github.com/ngkim/stack_ops.git
cd /root/workspace/stack_ops/iptables
./apply-iptables.sh
