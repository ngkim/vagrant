#!/bin/bash

source "./00_check_config.sh"
source "$WORK_HOME/include/neutron_util.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi


