#!/bin/bash

source "./00_check_config.sh"

init_network_interfaces() {
	# ------------------------------------------------------------------------------
	print_title "/etc/network/interfaces"
	# ------------------------------------------------------------------------------
	
	cat > /etc/network/interfaces<<EOF
# The loopback network interface
auto lo
iface lo inet loopback

source /etc/network/interfaces.d/*.cfg
EOF
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
${CTRL_MGMT_IP} controller
EOF

}

init_network_interfaces
config_mgmt_interface ${CTRL_MGMT_NIC} ${CTRL_MGMT_IP} ${MGMT_SUBNET}
config_external_interface ${EXT_NIC}
config_hosts
