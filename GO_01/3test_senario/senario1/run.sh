#!/bin/bash

# senario.txt 파일에 있는 내용을 실행한다.

customer=$1
if [[ -z "$customer" ]]; then
    echo "에려  :: customer 이름을 입력하세요!!!"
    echo "사용법:: run.sh customer_name"
    exit
fi

echo "##########################################################################"    
echo "(#) 프로그램 설명"
echo "##########################################################################"    
cat ./_senario.txt | more
echo "##########################################################################"    

source ./common_env $customer
source ./common_lib



source ./1make_account_and_security.sh
    make_tenant
    echo
    make_user
    echo
    member_role_create
    echo
    add_user_member_role
    echo
    add_tenant_default_security_group
    echo
    make_user_keypair
    echo

source ./2change_user_quota.sh
    update_user_nova_quota
    echo
    update_user_neutron_quota
    echo
    update_user_cinder_quota
    echo

source ./3make_default_network.sh
    make_user_guest_network
    echo
    make_user_guest_subnet
    echo
    make_user_router
    echo
    add_guest_subnet_interface_to_user_router
    echo
    set_external_gateway_to_user_router
    echo

source ./4make_hybrid_network.sh
    make_user_hybrid_green_network
    echo
    make_user_hybrid_green_subnet
    echo
    make_user_hybrid_orange_network
    echo
    make_user_hybrid_orange_subnet
    echo

source ./50make_vm_for_test.sh    
    make_user_utm_vm    ${customer}utm    $UTM_IMAGE    global_mgmt_net $GREEN_NET  $ORANGE_NET $RED_NET seocho.seoul.zo.kt cnode01 53utm_bootstrap.sh
    echo
    make_user_green_vm  ${customer}client $CLIENT_IMAGE global_mgmt_net $GREEN_NET  seocho.seoul.zo.kt cnode01 51green_bootstrap.sh
    echo
    make_user_orange_vm ${customer}server $SERVER_IMAGE global_mgmt_net $ORANGE_NET seocho.seoul.zo.kt cnode01 52orange_bootstrap.sh
    echo
    
                
