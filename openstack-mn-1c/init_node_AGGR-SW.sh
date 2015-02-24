#!/bin/bash

###########################################################################
# Author: Namgon Kim
# Date: 2015. 02. 24
#
# OpenFlow 1.3-based configuration
# * open vswitch를 이용하여 스위칭
#   - inport, vlan_id기반으로 outport를 결정  
#   - 추가적인 action이 필요한 경우를 위해 EXT_GROUPS정의
#
###########################################################################

BR0="br-aggr"
BR0_ITFS=(  "eth1"  "eth2"  "eth3"  "eth4"  "eth5"  "eth6"  "eth7")

# the array index of EXT_GROUPS will be used for group id 
EXT_GROUPS[16]="push_vlan:0x8100,set_field:10-\>vlan_vid,output:6"
EXT_GROUPS[17]="strip_vlan,output:7"

# - SVC (VLAN 3000~4000) - All-in-one과 C-Node-1만 통신하므로 VLAN 구분없이 연결
#    . in_port:em1 -> output:em2   #All-in-one => C-Node-1
#    . in_port:em2 -> output:em1   #C-Node-1  => All-in-one
FLOW_RULES[1]="in_port=1 group=2"
FLOW_RULES[2]="in_port=2 group=1"

# - LAN (VLAN 10~2000) -  각 고객별로 고객이 지닌 모든 LAN용 VLAN에 대해 아래 룰을 반복 입력
#    * 고객 Office 트래픽 (VLAN 11)
#        . in_port:em3,vlan=11 -> output: em4   # All-in-one ==> C-Node-1
#		 . in_port:em4,vlan=11 -> output: em3   # C-Node-1 ==> All-in-one
#    * Server Farm 트래픽 (VLAN 10)
#        . in_port:em3,vlan=10 -> output: em4   # All-in-one ==> C-Node-1
#	     . in_port:em4,vlan=10 -> output: em3   # C-Node-1 ==> All-in-one
FLOW_RULES[3]="in_port=3 dl_vlan=11 group=4"
FLOW_RULES[4]="in_port=4 dl_vlan=11 group=3"
FLOW_RULES[5]="in_port=3 dl_vlan=10 group=4"
FLOW_RULES[6]="in_port=4 dl_vlan=10 group=3"

#- WAN (VLAN 10~2000) - 각 고객별로 고객이 지닌 모든 WAN용 VLAN에 대해 아래 룰을 반복 입력
#      . in_port:em6,vlan=10 -> strip_vlan,output: em7                                     # All-in-one ==> WAN (VLAN 태그 제거후 전달)
#      . in_port:em7 -> push_vlan:0x8100,set_field:10-\>vlan_vid,output: em6   # WAN ==> All-in-one (VLAN 태그 추가후 전달)
# 추가로 strip_vlan을 하는 group과 vlan_vid를 추가하는 group을 새로 지정
FLOW_RULES[7]="in_port=6 dl_vlan=10 group=17"
FLOW_RULES[8]="in_port=7 dl_vlan=10 group=16"

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
	declare -a GROUPS=("${!2}")
	
	for grp_id in ${!GROUPS[@]}; do
		action=${GROUPS[$grp_id]}
		add_group $BR_NAME $grp_id "all" $action	
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
ext_groups  $BR0 EXT_GROUPS[@] 
add_flows   $BR0 FLOW_RULES[@]
dump_groups $BR0
dump_flows  $BR0
