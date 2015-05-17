#!/bin/bash

BR1="br0"

# Use VLAN 2000 for external network connection
# BR1_MODE 0=access 1=trunk -1=not-added-to-ovs
BR1_MODE=(     0      0      0      0      0      0      0)
BR1_ITFS=("eth1" "eth2" "eth3" "eth4" "eth5" "eth6" "eth7")
BR1_TAGS=(    11     11     10     10   2000   2000   2000)

# make comma-separated string from a string for vlan trunk
# example) "1-4,7,9" ==> 1,2,3,4,7,9
str_trunk_to_comma() {
    str_trunk=$1
    str_comma=""

    arr_trunk=(${str_trunk//,/ })
    for trunk in "${arr_trunk[@]}"; do
      list_vlan=(${trunk//-/ })
      len_list_vlan=${#list_vlan[@]}
      if [ $len_list_vlan -eq 2 ]; then
        start_idx=${list_vlan[0]}
        __end_idx=${list_vlan[1]}

        seq=`seq $start_idx $__end_idx`
        str_comma+=" $seq"
      else
        str_comma+=" $trunk"
      fi  
    done
   
    # print result string with triming leading and trailing spaces 
    str_comma=`echo $str_comma | sed -e 's/^ *//' -e 's/ *$//'`
    echo $str_comma | sed 's/ /,/g'

}

init_ovs() {
	BR_NAME=$1
	declare -a BR_ITFS=("${!2}")
	declare -a BR_TAGS=("${!3}")
	declare -a BR_MODE=("${!4}")

	sudo ovs-vsctl add-br $BR_NAME

	for idx in ${!BR_ITFS[@]}; do
                itf=${BR_ITFS[$idx]}
                tag=${BR_TAGS[$idx]}
                mod=${BR_MODE[$idx]}

                if [ $mod == 0 ]; then
                  # access vlan
		  echo "ovs-vsctl add-port $BR_NAME $itf tag=$tag"
		  sudo ovs-vsctl add-port $BR_NAME $itf tag=$tag
                elif [ $mod == 1 ]; then
                  # trunk port
                  vlan_trunks=$(str_trunk_to_comma $tag)
                  echo "ovs-vsctl add-port $BR_NAME $itf trunk=$vlan_trunks"
		  sudo ovs-vsctl add-port $BR_NAME $itf trunk=$vlan_trunks
                fi
		sudo ifconfig $itf up
	done
}

init_ovs $BR1 BR1_ITFS[@] BR1_TAGS[@] BR1_MODE[@]
