#!/bin/bash

BR1="br-svc"
BR1_ITFS=("eth1" "eth2")

init_ovs() {
	BR_NAME=$1
	declare -a BR_ITFS=("${!2}")

	sudo ovs-vsctl add-br $BR_NAME

	for itf in ${BR_ITFS[@]}; do
		sudo ifconfig $itf up
		sudo ovs-vsctl add-port $BR_NAME $itf
	done
}

init_ovs $BR1 BR1_ITFS[@]


