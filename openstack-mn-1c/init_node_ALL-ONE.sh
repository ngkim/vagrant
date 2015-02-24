#!/bin/bash

# MGMT 인터페이스로 C1과 통신 확인
# VLAN 10으로 LAN 인터페이스(eth5)로 C1과 연결확인 - flow table 확인
# VLAN 11으로 LAN 인터페이스(eth5)로 C1과 연결확인 - flow table 확인
# VLAN 10으로 WAN 인터페이스(eth6)로 인터넷 되는지 확인 - flow table 확인

sudo ifconfig eth1 10.0.0.101/24 up

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

sudo ifconfig eth5 up
echo "4. configure an interface for vlan 10 (eth5)"
sudo vconfig add eth5 10
sudo ifconfig eth5.10 192.168.10.1/24 up
	
echo "5. configure an interface for vlan 11 (eth5)"
sudo vconfig add eth5 11
sudo ifconfig eth5.11 192.168.11.1/24 up

sudo ifconfig eth6 up	
echo "6. configure an interface for vlan 10 (eth6)"
sudo vconfig add eth6 10
sudo ifconfig eth6.10 211.224.204.201/25 up