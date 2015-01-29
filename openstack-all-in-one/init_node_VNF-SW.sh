#!/bin/bash

BR1="br-vnf"
# Use VLAN 2000 for external network connection
BR1_ITFS=("eth1" "eth2" "eth3" "eth4" "eth5" "eth6" "eth7")
BR1_TAGS=(11 10 -1 -1 -1 2000 2000)

init_ovs() {
	BR_NAME=$1
	declare -a BR_ITFS=("${!2}")
	declare -a BR_TAGS=("${!3}")

	sudo ovs-vsctl add-br $BR_NAME

	for idx in ${!BR_ITFS[@]}; do
                itf=${BR_ITFS[$idx]}
                tag=${BR_TAGS[$idx]}

		sudo ifconfig $itf up
                if [ "$tag" != "-1" ]; then
		  sudo ovs-vsctl add-port $BR_NAME $itf tag=$tag
                else
		  sudo ovs-vsctl add-port $BR_NAME $itf
                fi
	done
}

init_ovs $BR1 BR1_ITFS[@] BR1_TAGS[@]
