#!/bin/bash

source "./00_check_config.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

cmd="neutron net-create $TENANT_NET"
run_commands $cmd

cmd="neutron subnet-create $TENANT_NET --name $TENANT_SBNET \
  		--gateway $TENANT_NETWORK_GW \
  		--dns-nameserver $DNS_NAMESERVER \
  		$TENANT_NETWORK_CIDR"
run_commands $cmd 

cmd="neutron router-create $TENANT_ROUTER"
run_commands $cmd

cmd="neutron router-interface-add $TENANT_ROUTER $TENANT_SBNET"
run_commands $cmd

cmd="neutron router-gateway-set $TENANT_ROUTER $EXT_NET"
run_commands $cmd
