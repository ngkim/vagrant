#!/bin/bash

source "./00_check_config.sh"

init_network_interfaces() {
	# ------------------------------------------------------------------------------
	print_title "/etc/network/interfaces"
	# ------------------------------------------------------------------------------

        apt-get install -y bridge-utils
	
	cat > /etc/network/interfaces<<EOF
# The loopback network interface
auto lo
iface lo inet loopback

source /etc/network/interfaces.d/*.cfg
EOF
}

config_public_mgmt_interface() {
	local PUB_NIC=$1
	local PUB_IP=$2
	local PUB_SBNET=$3
	local PUB_GW=$4
	local PUB_DNS=$5
	
	# ------------------------------------------------------------------------------
	print_title "public management network interface: $PUB_NIC"
	# ------------------------------------------------------------------------------
	
	cat > /etc/network/interfaces.d/$PUB_NIC.cfg <<EOF
# The primary network interface
auto $PUB_NIC
iface $PUB_NIC inet static
        address $PUB_IP
        netmask $PUB_SUBNET
        gateway $PUB_GW
        # dns-* options are implemented by the resolvconf package, if installed
        dns-nameservers $PUB_DNS
EOF
	ifup $PUB_NIC
}

config_mgmt_interface() {
	local NIC=$1
	local MGMT_IP=$2
	local MGMT_SBNET=$3
	
	# ------------------------------------------------------------------------------
	print_title "management network interface: $NIC"
	# ------------------------------------------------------------------------------
	
	cat > /etc/network/interfaces.d/$NIC.cfg <<EOF
# management network
auto $NIC
iface $NIC inet static
    address $MGMT_IP
    netmask $MGMT_SBNET
    bridge_ports none
EOF
	ifup $NIC
}

config_external_interface() {
	local NIC=$1
	
	# ------------------------------------------------------------------------------	
	print_title "external network interface: $NIC"
	# ------------------------------------------------------------------------------
	
	cat > /etc/network/interfaces.d/$NIC.cfg <<EOF
auto $NIC
iface $NIC inet manual
    up ip link set dev \$IFACE up
    down ip link set dev \$IFACE down
EOF
	ifup $NIC
}

config_hosts() {
	print_title "/etc/hosts"
	
	cat > /etc/hosts <<EOF
127.0.0.1 localhost
${CTRL_MGMT_IP} ${BOXNAME} $HOSTNAME
EOF

}

init_network_interfaces
if [ ! -z $PUBLIC_NIC ]; then
  config_public_mgmt_interface $PUBLIC_NIC $PUBLIC_IP $PUBLIC_SUBNET $PUBLIC_GW $PUBLIC_DNS
fi
if [ ! -z $CTRL_MGMT_NIC ]; then
  config_mgmt_interface ${CTRL_MGMT_NIC} ${CTRL_MGMT_IP} ${MGMT_SUBNET}
fi
if [ ! -z $EXT_NIC ]; then
  config_external_interface ${EXT_NIC}
fi
config_hosts
