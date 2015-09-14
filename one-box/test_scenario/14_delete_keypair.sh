#!/bin/bash

source "ext-net.ini"
source "../include/command_util.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

cmd="nova keypair-list | awk '/${ACCESS_KEY}/{print \$2}'"
run_commands_return $cmd
KEY_ID=$RET

if [ ! -z $KEY_ID ]; then
	cmd="nova keypair-delete $ACCESS_KEY"
	run_commands $cmd
fi