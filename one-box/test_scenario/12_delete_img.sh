#!/bin/bash

source "./ext-net.ini"
source "../include/command_util.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

cmd="glance image-list | awk '/${IMAGE_NAME}/{print \$2}'"
run_commands_return $cmd
IMAGE_ID=$RET

if [ ! -z ${IMAGE_ID} ]; then
	cmd="glance image-delete ${IMAGE_ID}"
	run_commands $cmd
fi
