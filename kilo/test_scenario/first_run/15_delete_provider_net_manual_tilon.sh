#!/bin/bash

source "provider-net.ini"
source "../include/command_util.sh"
source "../include/provider_net_util.sh"

VLAN_GR="120"
SBN_GRN="subnet_vlan_${VLAN_GR}"
NET_GRN="net_vlan_${VLAN_GR}"

delete_provider_subnet 	$SBN_GRN
delete_provider_net 	$NET_GRN

VLAN_GR="121"
SBN_GRN="subnet_vlan_${VLAN_GR}"
NET_GRN="net_vlan_${VLAN_GR}"

delete_provider_subnet 	$SBN_GRN
delete_provider_net 	$NET_GRN

VLAN_GR="15"
SBN_GRN="subnet_vlan_${VLAN_GR}"
NET_GRN="net_vlan_${VLAN_GR}"

delete_provider_subnet 	$SBN_GRN
delete_provider_net 	$NET_GRN

VLAN_GR="120"
SBN_GRN="subnet_vlan_wan_${VLAN_GR}"
NET_GRN="net_vlan_wan_${VLAN_GR}"

delete_provider_subnet 	$SBN_GRN
delete_provider_net 	$NET_GRN
