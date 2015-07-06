#!/bin/bash

source 'provider-net-tilon.ini'
source '../include/command_util.sh'

# TODO: Tenant ID 옵션 지원

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/openstack_rc
fi

IMAGE_ID=`glance image-list | awk '/'$VM_IMAGE'/{print $2}'`
NET_MGMT_ID=`neutron net-list | awk '/'$NET_MGMT'/{print $2}'`
NET_WAN_ID=`neutron net-list | awk '/'$NET_WAN'/{print $2}'`
NET_LAN_1_ID=`neutron net-list | awk '/'$NET_LAN_1'/{print $2}'`
NET_LAN_2_ID=`neutron net-list | awk '/'$NET_LAN_2'/{print $2}'`
NET_LAN_3_ID=`neutron net-list | awk '/'$NET_LAN_3'/{print $2}'`

source "bootstrap/provider_bootstrap_template_tilon.sh" \
	"dat/provider-$VM_NAME.dat" \
	$NIC_WAN \
	$NIC_LAN_1 \
	$NIC_LAN_2 \
	$NIC_LAN_3 \
	$IP_WAN \
	$IP_LAN_1 \
	$IP_LAN_2 \
	$IP_LAN_3

do_nova_boot() {
	# TODO: 입력값의 오류 확인, empty string일 경우 return
	
    cmd="nova boot $VM_NAME \
        --flavor $VM_FLAVOR_UTM \
        --image $IMAGE_ID \
	--nic net-id=$NET_MGMT_ID \
        --nic net-id=$NET_WAN_ID \
	--nic net-id=$NET_LAN_1_ID \
	--nic net-id=$NET_LAN_2_ID \
	--nic net-id=$NET_LAN_3_ID \
        --availability-zone $AV_ZONE \
        --security-groups default \
        --file /root/.ssh/authorized_keys=./id_rsa.pub \
        --user-data dat/provider-$VM_NAME.dat"
    
    run_commands $cmd
}

do_nova_boot
