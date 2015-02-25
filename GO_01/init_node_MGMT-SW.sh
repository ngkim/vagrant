#!/bin/bash

###########################################################################
# Author: Namgon Kim
# Date: 2015. 02. 24
#
# OpenFlow 1.3-based configuration
# * open vswitch를 이용하여 스위칭
#   - inport, vlan_id기반으로 outport를 결정  
#   - 추가적인 action이 필요한 경우를 위해 EXT_GROUPS정의
#   - (중요) 
#    VLAN이 있는 flow와 VLAN이 없는 flow에 대해서 동일한 FLOW_RULE을 이용하기 위해
#    FLOW_RULE배열을 match와 action이 빈 칸으로 구분되는 형태로 변경
###########################################################################

BR0="br-mgmt"
BR0_ITFS=(  "eth1"  "eth2"  "eth3"  "eth4"  "eth5"  "eth6"  "eth7")

#FLOW_RULES[1]="priority=0 actions=NORMAL"

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

ext_groups() {
	BR_NAME=$1
    declare -a GRPS=("${!2}")
    base_idx=$3
    
    if [ -z $base_idx ]; then base_idx=0; fi
    
    for arr_idx in ${!GRPS[@]}; do
    	action=${GRPS[$arr_idx]}
    	
    	grp_id=$((arr_idx + base_idx))
        add_group $BR_NAME $grp_id "all" $action
    done
}

add_flow() {
	BR_NAME=$1
    MATCH_=$2
    ACTION=$3
    TBL_ID=$4   
    
    if [ -z $TBL_ID ]; then TBL_ID=0; fi

    cmd="sudo ovs-ofctl -O OpenFlow13 add-flow $BR_NAME \
             table=$TBL_ID,$MATCH_,actions=$ACTION"
    run_commands $cmd
}

add_flows() {
	BR_NAME=$1
	declare -a FLOW_RULE=("${!2}")
	
	# use ${!FLOW_RULE[@]} instead of ${FLOW_RULE[@]}
	# ${FLOW_RULE[@]}를 사용하면 bash가 빈칸으로 구분된 문자열을 배열 element로 인식  
	for idx in ${!FLOW_RULE[@]}; do
		rule=${FLOW_RULE[$idx]}
        
        echo "rule= $rule"
        match_=`echo $rule | awk '{print $1}'`
        action=`echo $rule | awk '{print $2}'`
        
        echo "add_flow $BR_NAME $match_ $action"
        add_flow $BR_NAME $match_ $action			
	done		
}

# remove all flow entries from ovs
clear_flows() {
	BR_NAME=$1
	
	cmd="sudo ovs-ofctl -O Openflow13 del-flows $BR_NAME"
	run_commands $cmd						
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
ext_groups  $BR0 EXT_GROUPS[@] $BASE_GROUP_ID
# Do not clear flows to use default action
# clear_flows $BR0 
add_flows   $BR0 FLOW_RULES[@]
dump_groups $BR0
dump_flows  $BR0
