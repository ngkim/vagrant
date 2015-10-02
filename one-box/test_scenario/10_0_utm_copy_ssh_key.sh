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

print_ok() {
  echo "OK"
}

print_error() {
  MSG=$1
  echo "ERR $MSG"
  exit 0
}

if [ -z $2 ]; then 
  #usage
  print_error USAGE
fi

#################################################################

MGMT_IP=$1
PASSWD=$2

SSH_KEY="/root/.ssh/id_rsa.pub"

#################################################################

ip_cmd() {
  NETNS=`ip netns | grep qrouter`
  cmd="ip netns exec $NETNS $*"
  #run_commands_without_echo $cmd &> /dev/null
  run_commands $cmd
}

#################################################################

#print_title "*** copy ssh-key to ${MGMT_IP}"
if [ -f ${SSH_KEY} ]; then
  NSNAME=`ip netns | grep qrouter`
  ./10_0_utm_copy_ssh_key.exp ${MGMT_IP} $NSNAME $PASSWD  &> /dev/null
  print_ok
else
  print_msg "*** no ssh key file exist"
  ls ${SSH_KEY}
  print_msg "*** run ssh-keygen -t rsa"
  print_error
fi

#################################################################

#print_title "*** Upload config scripts: ./utm_config"
ip_cmd scp -r -oStrictHostKeyChecking=no utm_config/ ${MGMT_IP}: &> /dev/null

#print_title "*** make config scripts executable"
ip_cmd ssh -oStrictHostKeyChecking=no ${MGMT_IP} chmod +x utm_config/*.sh &> /dev/null

