#!/bin/bash

#source "provider-net.ini"
source "../include/command_util.sh"
source "../include/provider_net_util.sh"

VLAN_GR="120"
PHYSNET="physnet_lan"
CIDR_GR="10.10.4.0/24"
SBN_GRN="subnet_vlan_${VLAN_GR}"
NET_GRN="net_vlan_${VLAN_GR}"

create_provider_net 	$NET_GRN $PHYSNET $VLAN_GR
create_provider_subnet 	$NET_GRN $SBN_GRN $CIDR_GR

VLAN_GR="121"
PHYSNET="physnet_lan"
CIDR_GR="211.193.42.88/29"
SBN_GRN="subnet_vlan_${VLAN_GR}"
NET_GRN="net_vlan_${VLAN_GR}"

create_provider_net 	$NET_GRN $PHYSNET $VLAN_GR
create_provider_subnet 	$NET_GRN $SBN_GRN $CIDR_GR

VLAN_GR="15"
PHYSNET="physnet_lan"
CIDR_GR="211.193.42.1/26"
SBN_GRN="subnet_vlan_${VLAN_GR}"
NET_GRN="net_vlan_${VLAN_GR}"

create_provider_net 	$NET_GRN $PHYSNET $VLAN_GR
create_provider_subnet 	$NET_GRN $SBN_GRN $CIDR_GR

VLAN_GR="120"
PHYSNET="physnet_wan"
CIDR_GR="211.196.251.154/30"
SBN_GRN="subnet_vlan_wan_${VLAN_GR}"
NET_GRN="net_vlan_wan_${VLAN_GR}"

create_provider_net 	$NET_GRN $PHYSNET $VLAN_GR
create_provider_subnet 	$NET_GRN $SBN_GRN $CIDR_GR
