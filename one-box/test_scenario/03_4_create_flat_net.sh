#!/bin/bash

source "./00_check_config.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

source "$WORK_HOME/include/provider_net_util.sh"

#==================================================================
print_title "PROVIDER_NET: RED"
#==================================================================
create_flat_net $RED_NET $RED_PHYSNET
create_provider_subnet   $RED_NET $RED_SBNET $RED_NETWORK_CIDR

