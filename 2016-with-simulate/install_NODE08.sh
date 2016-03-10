#!/bin/bash

NIC="eth1"
IP="192.168.100.8"
SBNET="255.255.255.0"
GW="192.168.100.1"
DNS="168.126.63.1"

config_external_interface() {
        local PUB_NIC=$1
        local PUB_IP=$2
        local PUB_SBNET=$3
        local PUB_GW=$4
        local PUB_DNS=$5

        # ------------------------------------------------------------------------------
        echo "*** config external network interface: $PUB_NIC"
        # ------------------------------------------------------------------------------

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
        ifup $PUB_NIC
}

ifconfig $NIC 0
ifconfig $NIC down
ifdown $NIC
config_external_interface $NIC $IP $SBNET $GW $DNS
#ifconfig eth1 $IP
#ip route del default
#ip route add default via $GW


