#!/bin/bash

#################################################################
# DESC: config vUTM with given management ip
# AUTH: Namgon Kim (day10000@gmail.com)
# DATE: 2015. 09. 22
#################################################################

source "./00_check_config.sh"

usage() {
  echo "Usage: $0 [MGMT_IP]"
  echo "   ex) $0 192.168.10.1"
  exit 0
}

print_ok() {
  echo "OK"
}

print_error() {
  MSG=$1
  echo "ERR $POS"
  exit 0
}

if [ -z $1 ]; then 
  #usage
  print_error USAGE
fi

#################################################################

MGMT_IP=$1

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

config_dhcp() {
  local SCRIPT="./utm_config/ktutm_setup_dhcp.sh"
  local CONFIG="/var/efw/dhcp/settings"

#  DNS1_GREEN
#  DOMAIN_NAME_GREEN
#  ENABLE_GREEN
#  END_ADDR_GREEN
#  GATEWAY_GREEN
#  START_ADDR_GREEN

  #print_title "*** Run update: $SCRIPT"
  ip_cmd ssh -oStrictHostKeyChecking=no ${MGMT_IP} $SCRIPT \
				8.8.8.8 \
				localdomain \
                                on \
				192.168.0.200 \
				192.168.0.254 \
				192.168.0.101

  #check_result $CONFIG

  restart_service dhcp.updatewizard

  print_ok
}

config_dhcp
