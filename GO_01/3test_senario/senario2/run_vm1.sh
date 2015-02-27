#!/bin/bash

customer=$1
if [[ -z "$customer" ]]; then
    echo "에려  :: customer 이름을 입력하세요!!!"
    echo "사용법:: run.sh customer_name"
    exit
fi


source ./common_env.sh $customer
source ./common_lib.sh

function get_max_ip_seed_num() {

    local  _result_ptr=$1
    local  local_result

    # 데이터베이스에서 global mgmt net에 할당된 IP 최대값을 이용해서 seednum 구함
    query="
	    select max(cast(SUBSTRING_INDEX(ip_address,'.',-1) as unsigned))
	    from neutron.ipallocations
	    where ip_address like '10.10.10.%' "

    seed_num=$(echo $query | mysql -N -uroot -pohhberry3333 -h localhost)
    
    eval $_result_ptr=$seed_num
}

source ./5make_vm_for_test.sh
    make_user_utm_vm    ${customer}_utm    $UTM_IMAGE    global_mgmt_net \
        $GREEN_NET  $ORANGE_NET $RED_NET $AVAILABILITY_ZONE $CNODE01 ./template/53utm_bootstrap.sh
    echo
    make_user_green_vm  ${customer}_client $CLIENT_IMAGE global_mgmt_net \
        $GREEN_NET  $AVAILABILITY_ZONE $CNODE02 ./template/51green_bootstrap.sh
        
    echo
    #make_user_orange_vm ${customer}_server $SERVER_IMAGE global_mgmt_net \
    #    $ORANGE_NET $AVAILABILITY_ZONE $CNODE02 52orange_bootstrap.sh    
    
    
    get_max_ip_seed_num seed_num
    
    let "seed_num=seed_num+5"
    mgmt_ip="10.10.10.${seed_num}"
    let "seed_num=seed_num+50"
    orange_ip="192.168.0.${seed_num}"

    printf "# ---------------------------------------------------------------------\n"
    printf "%-30s => %s  \n" mgmt_ip    $mgmt_ip
    printf "%-30s => %s  \n" orange_ip  $orange_ip
    printf "# ---------------------------------------------------------------------\n"

    source ./template/orange_bootstrap_template.sh ./bootstrap/orange_bootstrap_file.sh eth1 $orange_ip 255.255.255.0
    
    cat ./bootstrap/orange_bootstrap_file.sh

    make_user_orange_vm_with_fixed_ip ${customer}_server $SERVER_IMAGE \
        $mgmt_ip global_mgmt_net global_mgmt_subnet \
        $orange_ip $ORANGE_NET $ORANGE_SUBNET \
        $AVAILABILITY_ZONE $CNODE02 ./bootstrap/orange_bootstrap_file.sh
