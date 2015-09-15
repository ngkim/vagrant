#!/bin/bash

source "./00_check_config.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

# mgmt
cmd="neutron net-list | awk '/${TENANT_NET}/{print \$2}'"
run_commands_return $cmd
MGMT_NET_ID=$RET

# blue
cmd="neutron net-list | awk '/${BLU_NET}/{print \$2}'"
run_commands_return $cmd
BLU_NET_ID=$RET

create_port_in_provider_net() {
  local NET_NAME=$1
  local SBNET_NAME=$2
  local _NETWORK_IP=$3

  cmd="neutron net-list | awk '/${NET_NAME}/{print \$2}'"
  run_commands_return $cmd
  local _NET_ID=$RET

  cmd="neutron subnet-list | awk '/${SBNET_NAME}/{print \$2}'"
  run_commands_return $cmd
  local _SBNET_ID=$RET

  cmd="neutron port-list | awk '/${_NETWORK_IP}/{print \$2}'"
  run_commands_return $cmd
  _PORT_ID=$RET

  if [ -z $_PORT_ID ]; then
    #cmd="neutron port-create $_NET_ID --fixed-ip subnet_id=$_SBNET_ID,ip_address=$_NETWORK_IP --port_security_enabled False | awk '/ id/{print \$4}'"
    cmd="neutron port-create $_NET_ID --fixed-ip subnet_id=$_SBNET_ID,ip_address=$_NETWORK_IP | awk '/ id/{print \$4}'"
    run_commands_return $cmd
    _PORT_ID=$RET
  fi

}

# red-net-port
create_port_in_provider_net $RED_NET $RED_SBNET $RED_NETWORK_IP
RED_PORT_ID=$_PORT_ID

# green-net-port
create_port_in_provider_net $GRN_NET $GRN_SBNET $GRN_NETWORK_IP
GRN_PORT_ID=$_PORT_ID

# orange-net-port
create_port_in_provider_net $ORG_NET $ORG_SBNET $ORG_NETWORK_IP
ORG_PORT_ID=$_PORT_ID

do_nova_boot() {
    local _VM_NAME=$1
    local _VM_IMAGE=$2

    # image id
    cmd="glance image-list | awk '/${_VM_IMAGE}/{print \$2}'"
    run_commands_return $cmd
    local IMAGE_ID=$RET

    cmd_nic1="--nic net-id=$MGMT_NET_ID \
        --nic port-id=$RED_PORT_ID \
        --nic port-id=$GRN_PORT_ID \
        --nic port-id=$ORG_PORT_ID \
        --nic net-id=$BLU_NET_ID"
 
    cmd_nic="--nic net-id=$MGMT_NET_ID \
        --nic port-id=$RED_PORT_ID \
        --nic net-id=$BLU_NET_ID"
 
    cmd="nova boot $_VM_NAME \
        --flavor 3 \
        --key-name $ACCESS_KEY \
        --image $IMAGE_ID \
        $cmd_nic \
        --availability-zone $AV_ZONE \
        --security-groups default"

    run_commands $cmd
}

do_nova_boot $vUTM_NAME $UTM_IMAGE
