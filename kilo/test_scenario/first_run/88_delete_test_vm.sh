#!/bin/bash

cfg_file_name="provider-net.ini"

generate_provider-net-ini() {
	VLAN_GRN=$1
	VLAN_ORG=$2

cat > $cfg_file_name <<EOF
VLAN_RED=1999
VLAN_GRN=$VLAN_GRN
VLAN_ORG=$VLAN_ORG

NET_MGMT="global_mgmt_net"
NET_RED="net_red-shared-\$VLAN_RED"
NET_GRN="net-green-$VLAN_GRN"
NET_ORG="net-orange-$VLAN_ORG"

SBNET_RED="subnet-red-$VLAN_RED"
SBNET_GRN="subnet-green-$VLAN_GRN"
SBNET_ORG="subnet-orange-$VLAN_ORG"

GW_RED="221.145.180.1"
CIDR_RED="221.145.180.0/26"
CIDR_GRN="192.168.$VLAN_ORG.0/24"
CIDR_ORG="192.168.$VLAN_ORG.0/24"

PHYSNET_NAME="physnet_hybrid"

VM_NAME="test-vm-$VLAN_ORG"
#VM_FLAVOR_UTM=3
VM_FLAVOR_UTM=e8d89d72-bae0-4f02-a8c3-22f7ea940b80
VM_FLAVOR_END=2
#VM_IMAGE="vUTM_mgmt_eth0_0203"
VM_IMAGE="ubuntu-12.04"
AV_ZONE="seocho-az"
SERVER_UTM="cnode02"
SERVER_END="controller"

NIC_RED="eth1"
NIC_GRN="eth2"
NIC_ORG="eth3"

IP_BR0="192.168.$VLAN_ORG.1/24"
IP_RED="221.145.180.$VLAN_ORG/26"
IP_GRN="192.168.$VLAN_ORG.$VLAN_GRN/24"
IP_ORG="192.168.$VLAN_ORG.$VLAN_ORG/24"
EOF
}

for vlan_org in `seq 20 2 58`; do
	vlan_grn=$(echo $vlan_org + 1 | bc)
    echo "vlan_grn= $vlan_grn vlan_org= $vlan_org"
	generate_provider-net-ini $vlan_grn $vlan_org
    #./20_nova_delete_multinic_select_server_2_vms.sh
    ./19_nova_delete_multinic_select_server.sh
    #./15_delete_provider_net.sh
#    ./09_nova_boot_multinic_select_server.sh
#    ./10_nova_boot_multinic_select_server_2_vms.sh
done
