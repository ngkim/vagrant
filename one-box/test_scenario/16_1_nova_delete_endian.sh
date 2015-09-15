#!/bin/bash

source "ext-net.ini"
source "./00_check_config.sh"
source "$WORK_HOME/include/nova_util.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

delete_vm $vUTM_NAME
