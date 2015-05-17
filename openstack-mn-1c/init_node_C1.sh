#!/bin/bash

# MGMT 인터페이스로 All-in-one과 통신 확인
# VLAN 10으로 LAN 인터페이스(eth3)로 All-in-one과 연결확인 - flow table 확인
# VLAN 11으로 LAN 인터페이스(eth3)로 All-in-one과 연결확인 - flow table 확인
# WAN 인터페이스(eth4)로의 플로우는 구성되지 않아 동작안함

sudo ifconfig eth1 10.0.0.102/24 up	
	
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

sudo ifconfig eth3 up
echo "4. configure an interface for vlan 10 (eth3)"
sudo vconfig add eth3 10
sudo ifconfig eth3.10 192.168.10.2/24 up
	
echo "5. configure an interface for vlan 11 (eth3)"
sudo vconfig add eth3 11
sudo ifconfig eth3.11 192.168.11.2/24 up

echo "6. network interface up (eth4)"
sudo ifconfig eth4 up	
