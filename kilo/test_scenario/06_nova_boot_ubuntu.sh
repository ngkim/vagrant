#!/bin/bash

source "ext-net.ini"
source "../include/command_util.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

cmd="glance image-list | awk '/${IMAGE_NAME}/{print \$2}'"
run_commands_return $cmd
IMAGE_ID=$RET

cmd="neutron net-list | awk '/${TENANT_NET}/{print \$2}'"
run_commands_return $cmd
NET_ID=$RET

do_nova_boot() {
    cmd="nova boot $VM_NAME \
        --flavor 3 \
        --key-name $ACCESS_KEY \
        --image $IMAGE_ID \
        --nic net-id=$NET_ID \
        --availability-zone $AV_ZONE \
        --security-groups default"

    run_commands $cmd
}

do_nova_boot
