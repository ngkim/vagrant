#!/bin/bash

source 'provider-net.ini'
source '../include/command_util.sh'

# TODO: Tenant ID 옵션 지원

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/openstack_rc
fi

IMAGE_ID=`glance image-list | awk '/'$VM_IMAGE'/{print $2}'`
NET_MGMT_ID=`neutron net-list | awk '/'$NET_MGMT'/{print $2}'`
NET_RED_ID=`neutron net-list | awk '/'$NET_RED'/{print $2}'`
NET_GRN_ID=`neutron net-list | awk '/'$NET_GRN'/{print $2}'`
NET_ORG_ID=`neutron net-list | awk '/'$NET_ORG'/{print $2}'`

GREEN_NODE_DATA="dat/provider-$VM_NAME-green.dat"
ORANGE_NODE_DATA="dat/provider-$VM_NAME-orange.dat"

source "bootstrap/provider_bootstrap_template_green_n_orange.sh" \
		$GREEN_NODE_DATA \
		"eth1" \
		$IP_GRN \
		$IP_BR0
		
source "bootstrap/provider_bootstrap_template_green_n_orange.sh" \
		$ORANGE_NODE_DATA \
		"eth1" \
		$IP_ORG \
		$IP_BR0

do_nova_boot_end_node() {
	# TODO: 입력값의 오류 확인, empty string일 경우 return
	END_VM_NAME=$1
	NET_END_NODE=$2
	END_NODE_DATA=$3
	
    cmd="nova boot $END_VM_NAME \
        --flavor $VM_FLAVOR_END \
        --image $IMAGE_ID \
		--nic net-id=$NET_MGMT_ID \
        --nic net-id=$NET_END_NODE \
        --availability-zone $AV_ZONE:$SERVER_END \
        --security-groups default \
        --user-data $END_NODE_DATA"
    
    run_commands $cmd
}

do_nova_boot_end_node "$VM_NAME-green"  $NET_GRN_ID $GREEN_NODE_DATA
do_nova_boot_end_node "$VM_NAME-orange" $NET_ORG_ID $ORANGE_NODE_DATA
