#!/bin/bash

#-----------------------------------------
DEV=eth1
IP="211.224.204.246"
SBNET="255.255.255.128"
GW="211.224.204.129"
DNS="8.8.8.8"
#-----------------------------------------

config_network() {
        local PUB_NIC=$1
        local PUB_IP=$2
        local PUB_SBNET=$3
        local PUB_GW=$4
        local PUB_DNS=$5

        cat > /etc/network/interfaces.d/$PUB_NIC.cfg <<EOF
# The primary network interface
auto $PUB_NIC
iface $PUB_NIC inet static
    address $PUB_IP
    netmask $PUB_SBNET
    gateway $PUB_GW
    # dns-* options are implemented by the resolvconf package, if installed
    dns-nameservers $PUB_DNS
EOF
}

config_network $DEV $IP $SBNET $GW $DNS
ip route del default
ifup $DEV

mkdir -p /root/workspace
