#!/bin/bash

source "./00_check_config.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

cmd="neutron net-create $BLU_NET"
run_commands $cmd

cmd="neutron subnet-create $BLU_NET --name $BLU_SBNET \
                --no-gateway
  		$BLU_NETWORK_CIDR"
run_commands $cmd 

