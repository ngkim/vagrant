#!/bin/bash

#################################################################
# DESC: config SNAT for vUTM with given red IP
# AUTH: Namgon Kim (day10000@gmail.com)
# DATE: 2015. 10. 03
#################################################################

source "./00_check_config.sh"

usage() {
  echo "Usage: $0 [MGMT_IP] [SBNET_LIST] [HOST_LIST] [PORT_LIST]"
  echo "   ex) $0 192.168.10.1 \
		  192.168.10.0/24&192.168.2.0/24&10.0.0.0/24&211.224.204.0/24
                  221.118.131.153&211.246.68.136 \
		  22&80&10443"
  exit 0
}

print_ok() {
  echo "OK"
}

print_error() {
  MSG=$*
  echo "ERR $MSG"
  exit 0
}

if [ -z $4 ]; then 
  #usage
  print_error USAGE: Check command usage
fi

#################################################################

MGMT_IP=$1
SBNET_LIST=$2
HOST_LIST=$3
PORT_LIST=$4

#################################################################

ip_cmd() {
  NETNS=`ip netns | grep qrouter`
  cmd="ip netns exec $NETNS $*"
  run_commands_without_echo $cmd &> /dev/null
}

check_result() {
  local CONFIG=$1

  print_title "*** Check result: $CONFIG"
  ip_cmd ssh -oStrictHostKeyChecking=no ${MGMT_IP} cat $CONFIG
}

restart_service() {
  local svc=$1

  #print_title "*** Restart service: $svc"
  ip_cmd ssh -oStrictHostKeyChecking=no ${MGMT_IP} jobcontrol request $svc
}

#################################################################

config_access() {
  local SCRIPT="./utm_config/ktutm_setup_access.sh"

  #print_title "*** Run update: $SCRIPT"
  ip_cmd ssh -oStrictHostKeyChecking=no ${MGMT_IP} $SCRIPT $SBNET_LIST $HOST_LIST $PORT_LIST

  restart_service setxtaccess
  print_ok
}

config_access


