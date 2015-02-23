#!/bin/bash


############################################################
# Author: Namgon Kim
# Date: 2015. 02. 23
#
# Open vSwitch의 OpenFlow 1.3 기능 테스트
# * open vswitch를 이용하여 스위칭
#   - inport, vlan_id기반으로 outport를 결정  
# * Follow instructions in 
#   - http://sdnhub.org/tutorials/openflow-1-3/
#
############################################################

BR0="br-mgmt"
BR0_ITFS=(  "eth1"  "eth2"  "eth3"  "eth4"  "eth5"  "eth6"  "eth7")

FLOW_RULE[0]="in_port=1,vlan_vid=10,actions=output:2"
FLOW_RULE[1]="in_port=1,vlan_vid=20,actions=output:3"
FLOW_RULE[2]="in_port=2,vlan_vid=10,actions=output:1"
FLOW_RULE[3]="in_port=3,vlan_vid=20,actions=output:1"

init_ovs() {
	BR_NAME=$1
	declare -a BR_ITFS=("${!2}")

	echo "ovs-vsctl add-br $BR_NAME"
	sudo ovs-vsctl add-br $BR_NAME
	
	echo "ovs-vsctl set bridge $BR_NAME protocols=OpenFlow13"
	sudo ovs-vsctl set bridge $BR_NAME protocols=OpenFlow13
	
	for itf in ${BR_ITFS[@]}; do
		echo "ovs-vsctl add-port $BR_NAME $itf"
		sudo ovs-vsctl add-port $BR_NAME $itf
		sudo ifconfig $itf up
	done
	
}

add_forwarding_rules() {
	BR_NAME=$1
	declare -a FLOW_RULES=("${!2}")
	
	for rule in ${FLOW_RULES[@]}; do
		echo "ovs-ofctl -O Openflow13 add-flow $BR_NAME $rule"
		sudo ovs-ofctl -O Openflow13 add-flow $BR_NAME $rule
	done
}

dump_flow_rules() {
	BR_NAME=$1
	echo "ovs-ofctl -O Openflow13 dump-flows $BR_NAME"
	sudo ovs-ofctl -O Openflow13 dump-flows $BR_NAME
}

init_ovs $BR0 BR0_ITFS[@]
add_forwarding_rules $BR0 FLOW_RULE[@]
dump_flow_rules $BR0
