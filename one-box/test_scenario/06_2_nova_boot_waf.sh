#!/bin/bash

source "./00_check_config.sh"
source "$WORK_HOME/include/neutron_util.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

# mgmt
cmd="neutron net-list | awk '/${TENANT_NET}/{print \$2}'"
run_commands_return $cmd
MGMT_NET_ID=$RET

# blue
#cmd="neutron net-list | awk '/${BLU_NET}/{print \$2}'"
#run_commands_return $cmd
#BLU_NET_ID=$RET

# orange-net-port
create_port_in_provider_net $ORG_NET $ORG_SBNET $ORG_WAF_IP
ORG_PORT_ID=$_PORT_ID

# local-net-port
create_port_in_provider_net $LOC_NET $LOC_SBNET $LOC_NETWORK_IP_WAF
LOC_PORT_ID=$_PORT_ID

do_nova_boot() {
    local _VM_NAME=$1
    local _VM_IMAGE=$2
    local _VM_FLAVOR=$3

    #--nic net-id=$BLU_NET_ID \

    # image id
    cmd="glance image-list | awk '/${_VM_IMAGE}/{print \$2}'"
    run_commands_return $cmd
    local IMAGE_ID=$RET

    cmd="nova boot $_VM_NAME \
        --flavor $_VM_FLAVOR \
        --key-name $ACCESS_KEY \
        --image $IMAGE_ID \
        --nic net-id=$MGMT_NET_ID \
        --nic port-id=$ORG_PORT_ID \
        --nic port-id=$LOC_PORT_ID \
        --availability-zone $AV_ZONE \
        --security-groups default"

    run_commands $cmd
}

do_nova_boot $vWAF_NAME $WAF_IMAGE $vWAF_FLAVOR
