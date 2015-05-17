#!/bin/bash

echo "1. configure apt-get proxy"
CACHE_SERVER="211.224.204.145:23142"
sudo cat > /etc/apt/apt.conf.d/02proxy <<EOF
Acquire::http { Proxy "http://$CACHE_SERVER"; };
EOF

echo "2. apt-get update"
sudo apt-get update
	
echo "3. apt-get install vlan iperf"
sudo apt-get install -y vlan iperf
sudo modprobe 8021q

sudo ifconfig eth1 up
echo "4. configure an interface for vlan 20"
sudo vconfig add eth1 20
sudo ifconfig eth1.20 192.168.20.2/24 up