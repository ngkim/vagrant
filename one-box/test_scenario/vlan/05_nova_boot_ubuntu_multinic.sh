#!/bin/bash

source "./00_check_config.sh"
source "$WORK_HOME/include/neutron_util.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

cmd="glance image-list | awk '/${IMAGE_LABEL}/{print \$2}'"
run_commands_return $cmd
IMAGE_ID=$RET

cmd="neutron net-list | awk '/${TENANT_NET}/{print \$2}'"
run_commands_return $cmd
MGMT_NET_ID=$RET

# red-net-port
create_port_in_provider_net $RED_NET $RED_SBNET $RED_NETWORK_IP
RED_PORT_ID=$_PORT_ID

# green-net-port
create_port_in_provider_net $GRN_NET $GRN_SBNET $GRN_NETWORK_IP
GRN_PORT_ID=$_PORT_ID

# orange-net-port
create_port_in_provider_net $ORG_NET $ORG_SBNET $ORG_NETWORK_IP
ORG_PORT_ID=$_PORT_ID

# local-net-port
create_port_in_provider_net $LOC_NET $LOC_SBNET $LOC_NETWORK_IP_UTM
LOC_PORT_ID=$_PORT_ID

do_nova_boot() {

    cmd_nic="--nic net-id=$MGMT_NET_ID \
        --nic port-id=$RED_PORT_ID \
        --nic port-id=$GRN_PORT_ID \
        --nic port-id=$ORG_PORT_ID \
        --nic port-id=$LOC_PORT_ID"
 
    cmd="nova boot ${VM_NAME} \
        --flavor 3 \
        --key-name $ACCESS_KEY \
        --image $IMAGE_ID \
        $cmd_nic \
        --availability-zone $AV_ZONE \
        --security-groups default"

    run_commands $cmd
}

do_nova_boot
