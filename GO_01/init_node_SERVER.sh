#!/bin/bash

# Server Node
# MGMT 인터페이스(eth1)로 다른 노드들과 통신
# ORANGE 인터페이스(eth2)로 vUTM과 통신
sudo ifconfig eth1 10.0.0.104/24 up

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

echo "4. configure the orange interface (eth2)"
sudo ifconfig eth2 192.168.10.10/24 up
	
echo "5. add route to public node through eth2"
sudo route add -net 221.155.188.0 netmask 255.255.255.0 gw 192.168.10.1 dev eth2