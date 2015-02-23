#!/bin/bash

###########################################################################
# Author: Namgon Kim
# Date: 2015. 02. 23
#
# Open vSwitch의 OpenFlow 1.3 기능 테스트
# * open vswitch를 이용하여 스위칭
#   - inport, vlan_id기반으로 outport를 결정  
# * Follow instructions in 
#   - http://sdnhub.org/tutorials/openflow-1-3/
#
###########################################################################

BR0="br-mgmt"
BR0_ITFS=(  "eth1"  "eth2"  "eth3"  "eth4"  "eth5"  "eth6"  "eth7")

FLOW_RULES[1]="in_port=1 dl_vlan=10 group=2"
FLOW_RULES[2]="in_port=1 dl_vlan=20 group=3"
FLOW_RULES[3]="in_port=2 dl_vlan=10 group=1"
FLOW_RULES[4]="in_port=3 dl_vlan=20 group=1"

###########################################################################

function run_commands() {
	_green=$(tput setaf 2)
	normal=$(tput sgr0)
	
	commands=$*
	echo -e ${_green}${commands}${normal}
	eval $commands
	echo
}

init_ovs() {
	BR_NAME=$1
	declare -a BR_ITFS=("${!2}")

	cmd="sudo ovs-vsctl add-br $BR_NAME"
	run_commands $cmd
	
	cmd="sudo ovs-vsctl set bridge $BR_NAME protocols=OpenFlow13"
	run_commands $cmd
	
	for itf in ${BR_ITFS[@]}; do
		cmd="sudo ovs-vsctl add-port $BR_NAME $itf"
		run_commands $cmd
		sudo ifconfig $itf up
	done	
}

add_group() {
	BR_NAME=$1
	GRP_ID=$2
	GRP_TYPE=$3
	GRP_BUCKET=$4
	
	cmd="sudo ovs-ofctl -O Openflow13 add-group $BR_NAME \
			group_id=$GRP_ID,type=$GRP_TYPE,bucket=$GRP_BUCKET"
			
	run_commands $cmd
}

add_groups() {
	BR_NAME=$1
	declare -a BR_ITFS=("${!2}")
	
	for arr_idx in ${!BR_ITFS[@]}; do
		# add 1 to arr_idx to make itf_idx start from 1
		itf_idx=$((arr_idx + 1))
		add_group $BR_NAME $itf_idx "all" "output:$itf_idx"	
	done
	
}

add_flow() {
	BR_NAME=$1
	IN_PORT=$2
	DL_VLAN=$3
	GRP_ID=$4
	TBL_ID=$5
	
	if [ -z $TBL_ID ]; then TBL_ID=0; fi
	
	cmd="sudo ovs-ofctl -O OpenFlow13 add-flow $BR_NAME \
			 table=$TBL_ID,$IN_PORT,$DL_VLAN,actions=$GRP_ID"
	run_commands $cmd
}

add_flows() {
	BR_NAME=$1
	declare -a FLOW_RULE=("${!2}")
	
	# use ${!FLOW_RULE[@]} instead of ${FLOW_RULE[@]}
	# ${FLOW_RULE[@]}를 사용하면 bash가 빈칸으로 구분된 문자열을 배열 element로 인식  
	for idx in ${!FLOW_RULE[@]}; do
		flow=${FLOW_RULE[$idx]}
		
		in_port=`echo $flow | awk '{print $1}'`
		dl_vlan=`echo $flow | awk '{print $2}'`
		grp_id_=`echo $flow | awk '{print $3}'`
		
		add_flow $BR_NAME $in_port $dl_vlan $grp_id_	
	done
}

dump_groups() {
	BR_NAME=$1
	
	cmd="sudo ovs-ofctl -O Openflow13 dump-groups $BR_NAME"
	run_commands $cmd
}

dump_flows() {
	BR_NAME=$1
	
	cmd="sudo ovs-ofctl -O Openflow13 dump-flows $BR_NAME"
	run_commands $cmd
}

init_ovs    $BR0 BR0_ITFS[@]
add_groups  $BR0 BR0_ITFS[@]
add_flows   $BR0 FLOW_RULES[@]
dump_groups $BR0
dump_flows  $BR0
