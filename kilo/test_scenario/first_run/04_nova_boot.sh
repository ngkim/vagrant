#!/bin/bash

source 'tenant-net.ini'
source '../include/command_util.sh'

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/openstack_rc
fi

IMAGE_ID=`glance image-list | awk '/'$IMAGE_NAME'/{print $2}'`
NET_ID=`neutron net-list | awk '/'$TENANT_NET'/{print $2}'`

do_nova_boot() {
    cmd="nova boot $TENANT_VM_NAME \
        --flavor 3 \
        --key-name $ACCESS_KEY \
        --image $IMAGE_ID \
        --nic net-id=$NET_ID \
        --availability-zone $AV_ZONE \
        --security-groups default"

    run_commands $cmd
}

do_nova_boot
