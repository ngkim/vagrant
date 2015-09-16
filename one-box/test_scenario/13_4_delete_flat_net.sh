#!/bin/bash

source "./00_check_config.sh"
source "$WORK_HOME/include/neutron_util.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

#==================================================================
print_title "DELETE PROVIDER_NET FLAT: RED"
#==================================================================
delete_subnet $RED_SBNET
delete_net $RED_NET


