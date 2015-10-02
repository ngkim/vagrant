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

config_internet_bridge() {
	local PUB_NIC=$1
	local PUB_IP=$2
	local PUB_SBNET=$3
	local PUB_GW=$4
	local PUB_DNS=$5
	
	# ------------------------------------------------------------------------------
	print_title " internet bridge: br-internet ($PUB_NIC)"
	# ------------------------------------------------------------------------------
	
	cat > /etc/network/interfaces.d/br-internet.cfg <<EOF
# The primary network interface
auto br-internet
iface br-internet inet static
    address $PUB_IP
    netmask $PUB_SUBNET
    gateway $PUB_GW
    # dns-* options are implemented by the resolvconf package, if installed
    dns-nameservers $PUB_DNS
    bridge_ports $PUB_NIC
EOF
	ifup br-internet
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
	print_title "internal management network: $NIC"
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

##############################################################################################
# /etc/hosts 
##############################################################################################
config_hosts() {
  print_title "/etc/hosts"

  if [ ${BOXNAME} == ${HOSTNAME} ]; then
    print_title "ERROR!!! HOSTNAME should not be the same with BOXNAME. It cloud make conflicts. HOSTNAME= ${HOSTNAME} BOXNAME= ${BOXNAME} !!!"
    exit 1
  fi
  cat > /etc/hosts <<EOF
127.0.0.1 localhost
${PUBLIC_IP} ${BOXNAME}
${CTRL_MGMT_IP} ${HOSTNAME}
EOF

}

init_network_interfaces
if [ ! -z $PUBLIC_NIC ]; then
  config_internet_bridge $PUBLIC_NIC $PUBLIC_IP $PUBLIC_SUBNET $PUBLIC_GW $PUBLIC_DNS
else
  print_title "ERROR!!! PUBLIC NIC has not been assigned!!!"
  exit 1
fi
if [ ! -z $CTRL_MGMT_NIC ]; then
  config_mgmt_interface ${CTRL_MGMT_NIC} ${CTRL_MGMT_IP} ${MGMT_SUBNET}
else
  print_title "ERROR!!! Internal Management Network has not been configured!!! Check your configurations!!!"
  exit 1
fi
if [ ! -z $EXT_NIC ]; then
  config_external_interface ${EXT_NIC}
fi
config_hosts
