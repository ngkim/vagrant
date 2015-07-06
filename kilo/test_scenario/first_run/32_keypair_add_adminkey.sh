#!/bin/bash

source 'tenant-net.ini'
source '../include/command_util.sh'

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/openstack_rc
fi

cmd="ssh-keygen -t rsa -f $ACCESS_KEY"
run_commands $cmd

cmd="nova keypair-delete $ACCESS_KEY"
run_commands $cmd

cmd="nova keypair-add --pub_key $PUB_KEY $ACCESS_KEY"
run_commands $cmd

cmd="nova keypair-show $ACCESS_KEY"
run_commands $cmd
