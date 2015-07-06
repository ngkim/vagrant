#!/bin/bash

source "ext-net.ini"
source "../include/command_util.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

cmd="neutron router-list | awk '/${TENANT_ROUTER}/{print \$2}'"
run_commands_return $cmd
TENANT_ROUTER_ID=$RET

cmd="neutron subnet-list | awk '/${TENANT_SBNET}/{print \$2}'"
run_commands_return $cmd
TENANT_SBNET_ID=$RET

cmd="neutron net-list | awk '/${TENANT_NET}/{print \$2}'"
run_commands_return $cmd
TENANT_NET_ID=$RET

cmd="neutron router-gateway-clear $TENANT_ROUTER_ID"
run_commands $cmd

cmd="neutron router-interface-delete $TENANT_ROUTER_ID $TENANT_SBNET"
run_commands $cmd

cmd="neutron router-delete $TENANT_ROUTER_ID"
run_commands $cmd

cmd="neutron subnet-delete $TENANT_SBNET_ID"
run_commands $cmd

cmd="neutron net-delete $TENANT_NET_ID"
run_commands $cmd


