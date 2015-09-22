#!/bin/bash

#################################################################
# DESC: copy ssh public key to remote host with expect shell
# AUTH: Namgon Kim (day10000@gmail.com)
# DATE: 2015. 09. 22
#################################################################

source "./00_check_config.sh"

usage() {
  echo "Usage: $0 [MGMT_IP] [PASSWORD]"
  echo "   ex) $0 192.168.10.1 abcdedfg"
  exit 0
}

if [ -z $2 ]; then 
  usage
fi

#################################################################

MGMT_IP=$1
PASSWD=$2

SSH_KEY="/root/.ssh/id_rsa.pub"

#################################################################

print_title "*** copy ssh-key to ${MGMT_IP}"
if [ -f ${SSH_KEY} ]; then
  NSNAME=`ip netns | grep qrouter`
  ./10_0_utm_copy_ssh_key.exp ${MGMT_IP} $NSNAME $PASSWD 
else
  print_msg "*** no ssh key file exist"
  ls ${SSH_KEY}
  print_msg "*** run ssh-keygen -t rsa"
fi

