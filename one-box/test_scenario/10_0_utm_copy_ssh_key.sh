#!/bin/bash

source "./00_check_config.sh"

TEST_UTM="root@192.168.10.39"
SSH_KEY="~/.ssh/id_rsa.pub"

ip_cmd() {
  cmd="ip netns exec `ip netns | grep qrouter` $*"
  run_commands $cmd
}

print_title "*** copy ssh-key to ${TEST_UTM}"
if [ -f ${SSH_KEY} ]; then
  ip_cmd scp ${SSH_KEY} ${TEST_UTM}:.ssh/authorized_keys
else
  print_msg "*** no ssh key file exist"
  print_msg "*** run ssh-keygen -t rsa"
fi

