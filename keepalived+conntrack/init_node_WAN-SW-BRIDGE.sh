#!/bin/bash

BR1="br0"

BR1_ITFS=("eth1" "eth2" "eth3" "eth4" "eth5" "eth6" "eth7")

init_bridge() {
	BR_NAME=$1
	declare -a BR_ITFS=("${!2}")
        
        sudo sysctl -w net.ipv4.ip_forward=1

	sudo brctl addbr $BR_NAME

	for idx in ${!BR_ITFS[@]}; do
            itf=${BR_ITFS[$idx]}

            echo "sudo brctl addif $BR_NAME $itf"
            sudo brctl addif $BR_NAME $itf
            sudo ifconfig $itf up
	done

        sudo ifconfig $BR_NAME up
}

sudo apt-get update
sudo apt-get install -y bridge-utils

init_bridge $BR1 BR1_ITFS[@]
