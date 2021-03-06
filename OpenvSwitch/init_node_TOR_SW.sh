#!/bin/bash

BR0="br-mgmt"
BR0_ITFS=("eth1" "eth2")

BR1="br-hybrid"
BR1_ITFS=("eth3" "eth4")

init_ovs() {
	BR_NAME=$1
	declare -a BR_ITFS=("${!2}")

	sudo ovs-vsctl add-br $BR_NAME

	for itf in ${BR_ITFS[@]}; do
		sudo ifconfig $itf up
		sudo ovs-vsctl add-port $BR_NAME $itf
	done
}

init_ovs $BR0 BR0_ITFS[@]
init_ovs $BR1 BR1_ITFS[@]


