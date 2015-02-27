#!/bin/bash

# senario.txt 파일에 있는 내용을 실행한다.

customer=$1
if [[ -z "$customer" ]]; then
    echo "에려  :: customer 이름을 입력하세요!!!"
    echo "사용법:: run.sh customer_name ip_seed_num"
    echo "    예:: run.sh forbiz 5"
    exit
fi

source ./common_env.sh $customer
source ./common_lib.sh

echo "
--------------------------------------------------------------------------------
    5make_multinic_vm_with_floating_ip_for_mgmt.sh
    
	    make_user_multinic_utm_vm ${customer}_multinic_utm $UTM_IMAGE \
	        global_mgmt_net $RED_NET $GREEN_NET $ORANGE_NET \
	        $AVAILABILITY_ZONE $CNODE01
	    
	    allocate_floating_ip_to_mgmt_vm ${customer}_multinic_utm
    
--------------------------------------------------------------------------------"
    
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then

source ./5make_multinic_vm_with_floating_ip_for_mgmt.sh

    make_user_multinic_nomgmt_utm_vm ${customer}_multinic_nomgmt_utm01 $UTM_IMAGE \
        $RED_NET $GREEN_NET $ORANGE_NET \
        $AVAILABILITY_ZONE $CNODE01
    
    # allocate_floating_ip_to_mgmt_vm ${customer}_multinic_nomgmt_utm01
        
fi    