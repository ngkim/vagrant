#!/bin/bash

source "ext-net.ini"
source "../include/command_util.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

cmd="nova list | awk '/${VM_NAME}/{print \$2}'"
run_commands_return $cmd
VM_ID=$RET

if [ ! -z $VM_ID ]; then
	echo "nova delete $VM_ID"
	nova delete $VM_ID
fi
