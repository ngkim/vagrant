#!/bin/bash

#################################################################
# DESC: config SNAT for vUTM with given red IP
# AUTH: Namgon Kim (day10000@gmail.com)
# DATE: 2015. 10. 03
#################################################################

source "./00_check_config.sh"

usage() {
  echo "Usage: $0 [MGMT_IP] [RED_IP] [Green_Subnet] [Orange_Subnet]"
  echo "   ex) $0 192.168.10.1 211.224.204.227 192.168.0.0/24 192.168.1.0/24"
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
RED_IP=$2
GRN_SBNET=$3
ORG_SBNET=$4

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

config_snat() {
  local SCRIPT="./utm_config/ktutm_setup_snat.sh"
  local CONFIG="/var/efw/snat/config"

#  RED_IP
#  GRN_SBNET
#  ORG_SBNET

  #print_title "*** Run update: $SCRIPT"
  ip_cmd ssh -oStrictHostKeyChecking=no ${MGMT_IP} $SCRIPT \
				${RED_IP} \
				${GRN_SBNET} \
				${ORG_SBNET}

  restart_service setsnat
  restart_service setoutgoing
  print_ok
}

config_snat


