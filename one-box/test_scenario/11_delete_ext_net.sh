#!/bin/bash

source "ext-net.ini"
source "../include/command_util.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/openstack_rc
fi

cmd="neutron subnet-list | awk '/$EXT_SUBNET/{print \$2}'"
run_commands_return $cmd
SBNET_ID=$RET

cmd="neutron net-list | awk '/$EXT_NET/{print \$2}'"
run_commands_return $cmd
NET_ID=$RET

if [ ! -z $SBNET_ID ]; then
  cmd="neutron subnet-delete $SBNET_ID"
  run_commands $cmd
fi

if [ ! -z $NET_ID ]; then
  cmd="neutron net-delete $NET_ID"
  run_commands $cmd
fi
