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

config_uplink() {
  local SCRIPT="./utm_config/ktutm_setup_uplink.sh"
  local CONFIG="/var/efw/uplinks/main/settings"

#  DEFAULT_GATEWAY
#  DNS1
#  DNS2
#  RED_ADDRESS
#  RED_BROADCAST
#  RED_CIDR
#  RED_IPS
#  RED_NETADDRESS
#  RED_NETMASK

  print_title "*** Run update: $SCRIPT"
  ip_cmd ssh -oStrictHostKeyChecking=no ${MGMT_IP} $SCRIPT \
				211.224.204.129 \
				8.8.8.8 \
				8.8.8.9 \
				211.224.204.216 \
				211.224.204.255 \
				25 \
				211.224.204.216/25 \
				211.224.204.128 \
				255.255.255.128

  check_result $CONFIG

  restart_service uplinksdaemonjob.updatewizard
}

config_uplink


