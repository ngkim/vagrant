#!/bin/bash

sudo ifconfig eth1 10.0.0.101/24 up

echo "1. configure apt-get proxy"
CACHE_SERVER="211.224.204.145:23142"
sudo cat > /etc/apt/apt.conf.d/02proxy <<EOF
Acquire::http { Proxy "http://$CACHE_SERVER"; };
EOF

echo "2. apt-get update"
sudo apt-get update

#sudo apt-get install -y vlan iperf
#sudo modprobe 8021q
#sudo ifconfig eth2 up
#sudo vconfig add eth2 2001
#sudo ifconfig eth2.2001 192.168.1.1/24 up
