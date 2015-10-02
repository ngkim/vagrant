#!/bin/bash

source "ext-net.ini"
source "../include/command_util.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

cmd="nova list | awk '/${VM_NAME_CIRROS}/{print \$2}'"
run_commands_return $cmd
VM_ID=$RET

for vid in $VM_ID; do
  if [ ! -z $vid ]; then
    echo "nova delete $vid"
    nova delete $vid
  fi
done
