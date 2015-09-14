#!/bin/bash

source "./ext-net.ini"
source "./00_check_config.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

cmd="neutron net-create --shared --router:external ${EXT_NET}"
run_commands $cmd

cmd="neutron subnet-create $EXT_NET --name $EXT_SUBNET \
  --allocation-pool start=$FLOATING_IP_START,end=$FLOATING_IP_END \
  --disable-dhcp --gateway $EXTERNAL_NETWORK_GATEWAY $EXTERNAL_NETWORK_CIDR"
run_commands $cmd
