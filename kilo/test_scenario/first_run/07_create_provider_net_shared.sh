#!/bin/bash

source "provider-net.ini"
source "../include/command_util.sh"
source "../include/provider_net_util.sh"

echo "======== PROVIDER NET: RED ========"
create_provider_net_shared 	$NET_RED $PHYSNET_NAME 	$VLAN_RED
create_provider_subnet_shared 	$NET_RED $SBNET_RED 	$CIDR_RED $GW_RED

