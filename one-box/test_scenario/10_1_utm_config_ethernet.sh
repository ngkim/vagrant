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

if [ -z $1 ]; then 
  usage
fi

#################################################################

MGMT_IP=$1

#################################################################

ip_cmd() {
  cmd="ip netns exec `ip netns | grep qrouter` $*"
  run_commands $cmd
}

check_result() {
  local CONFIG=$1

  print_title "*** Check result: $CONFIG"
  ip_cmd ssh -oStrictHostKeyChecking=no ${MGMT_IP} cat $CONFIG
}

restart_service() {
  local svc=$1

  print_title "*** Restart service: $svc"
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

  print_title "*** Run update: $SCRIPT"
  ip_cmd ssh -oStrictHostKeyChecking=no ${MGMT_IP} $SCRIPT \
				192.168.0.252 \
                                192.168.0.255 \
                                192.168.0.252/24 \
                                192.168.0.0 \
				192.168.1.252 \
                                192.168.1.255 \
                                24 \
                                192.168.1.252/24 \
                                192.168.1.0 \
                                255.255.255.0

  check_result $CONFIG

  restart_service network.updatewizard
}

config_ethernet
