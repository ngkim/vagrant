#!/bin/bash

#################################################################
# DESC: config vUTM with given management ip
# AUTH: Namgon Kim (day10000@gmail.com)
# DATE: 2015. 09. 22
#################################################################

source "./00_check_config.sh"

usage() {
  echo "Usage: $0 [MGMT_IP] [GREEN_IP] [ORANGE_IP]"
  echo "   ex) $0 192.168.10.1 192.168.0.252 192.168.1.252"
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

if [ -z $3 ]; then 
  #usage
  print_error USAGE
fi


#################################################################

MGMT_IP=$1
GREEN_IP=$2
ORANGE_IP=$3

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

config_ethernet() {
  local SCRIPT="./utm_config/ktutm_setup_eth.sh"
  local CONFIG="/var/efw/ethernet/settings"

#  GREEN_ADDRESS
#  GREEN_BROADCAST
#  GREEN_IPS
#  GREEN_NETADDRESS
#  ORANGE_ADDRESS
#  ORANGE_BROADCAST
#  ORANGE_CIDR
#  ORANGE_IPS
#  ORANGE_NETADDRESS
#  ORANGE_NETMASK

  #print_title "*** Run update: $SCRIPT"
  ip_cmd ssh -oStrictHostKeyChecking=no ${MGMT_IP} $SCRIPT \
				${GREEN_IP} \
                                192.168.0.255 \
                                ${GREEN_IP}/24 \
                                192.168.0.0 \
				${ORANGE_IP} \
                                192.168.1.255 \
                                24 \
                                ${ORANGE_IP}/24 \
                                192.168.1.0 \
                                255.255.255.0

  #check_result $CONFIG

  restart_service network.updatewizard
  print_ok
}

config_ethernet
