#!/bin/bash

source "./00_check_config.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

mkdir -p keys
cmd="echo -e  'y\\n' | ssh-keygen -q -t rsa -f keys/$ACCESS_KEY -N ''"
run_commands $cmd

cmd="nova keypair-list | awk '/${ACCESS_KEY}/{print \$2}'"
run_commands_return $cmd
KEY_ID=$RET

if [ ! -z $KEY_ID ]; then
	cmd="nova keypair-delete $ACCESS_KEY"
	run_commands $cmd
fi

cmd="nova keypair-add --pub_key keys/$PUB_KEY $ACCESS_KEY"
run_commands $cmd

cmd="nova keypair-show $ACCESS_KEY"
run_commands $cmd
