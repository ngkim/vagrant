#!/bin/bash

source "./00_check_config.sh"

TEST_UTM="root@192.168.10.39"

ip_cmd() {
  cmd="ip netns exec `ip netns | grep qrouter` $*"
  run_commands $cmd
}

check_result() {
  local CONFIG=$1

  print_title "*** Check result: $CONFIG"
  ip_cmd ssh -oStrictHostKeyChecking=no ${TEST_UTM} cat $CONFIG
}

restart_service() {
  local svc=$1

  print_title "*** Restart service: $svc"
  ip_cmd ssh -oStrictHostKeyChecking=no ${TEST_UTM} jobcontrol request $svc
}

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
  ip_cmd ssh -oStrictHostKeyChecking=no ${TEST_UTM} $SCRIPT \
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

config_dhcp() {
  local SCRIPT="./utm_config/ktutm_setup_dhcp.sh"
  local CONFIG="/var/efw/dhcp/settings"

#  DNS1_GREEN
#  DOMAIN_NAME_GREEN
#  ENABLE_GREEN
#  END_ADDR_GREEN
#  GATEWAY_GREEN
#  START_ADDR_GREEN

  print_title "*** Run update: $SCRIPT"
  ip_cmd ssh -oStrictHostKeyChecking=no ${TEST_UTM} $SCRIPT \
				8.8.8.8 \
				localdomain \
                                on \
				192.168.0.200 \
				192.168.0.254 \
				192.168.0.101

  check_result $CONFIG

  restart_service dhcp.updatewizard
}

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
  ip_cmd ssh -oStrictHostKeyChecking=no ${TEST_UTM} $SCRIPT \
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



print_title "*** Upload config scripts: ./utm_config"
ip_cmd scp -r -oStrictHostKeyChecking=no utm_config/ ${TEST_UTM}:
print_title "*** make config scripts executable"
ip_cmd ssh -oStrictHostKeyChecking=no ${TEST_UTM} chmod +x utm_config/*.sh

config_uplink
#config_dhcp
config_ethernet
