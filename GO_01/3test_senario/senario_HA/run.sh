#!/bin/bash

# senario.txt 파일에 있는 내용을 실행한다.

customer=$1
if [[ -z "$customer" ]]; then
    echo "에려  :: customer 이름을 입력하세요!!!"
    echo "사용법:: run.sh customer_name"
    echo "    예:: run.sh forbiz"
    exit
fi

echo "##########################################################################"
echo "(#) 프로그램 설명"
echo "##########################################################################"
cat ./_senario.txt
echo "##########################################################################"

source ./common_env.sh $customer
source ./common_lib.sh


echo "
--------------------------------------------------------------------------------
    1. 1make_account_and_security.sh
        - 고객과 관련된 계정을 생성하고 권한을 부여한다.
        - 계정(tenant/user/password)    ex) forbiz/forbiz/forbiz1234
        - 권한(member)                  ex) member
        - keypair/keypair.pub           ex) forbizkey/forbizkey.pub
        - security group(default)       ex) icmp, tcp(22,80,443,5001)
--------------------------------------------------------------------------------"

ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
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
fi


echo "
--------------------------------------------------------------------------------
    2. 2change_quota.sh
        - 고객과 관련된 Quota를 적절하게 조정한다.(기본적으로 10배씩 증가시킴)
        - nova      ex) instances 100/cores 200/ram 512000/floating-ips 100/metadata_items 1280/injected_files 50
        - neutron   ex) floatingip 500/network 100/port 5000/router 100/security_group 100/security_group_rule 1000
        - cinder    ex) gigabytes 10000/snapshots 100/volumes 100
--------------------------------------------------------------------------------"

ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
source ./2change_user_quota.sh
    update_user_nova_quota
    echo
    update_user_neutron_quota
    echo
    update_user_cinder_quota
    echo
fi

echo "
--------------------------------------------------------------------------------
    3. 3make_hybrid_network.sh
        - UTM 테스트를 위한 hybrid network 환경을 제공한다.
        - green_network         ex) forbiz_green_net
        - green_subnetwork      ex) forbiz_green_subnet
        - orange_network        ex) forbiz_orange_net
        - orange_subnetwork     ex) forbiz_orange_subnet
--------------------------------------------------------------------------------"
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
source ./3make_hybrid_network.sh
    make_user_hybrid_green_network
    echo
    make_user_hybrid_green_subnet
    echo
    make_user_hybrid_orange_network
    echo
    make_user_hybrid_orange_subnet
    echo
fi


echo "
--------------------------------------------------------------------------------
    4. 4make_vm_for_test.sh
--------------------------------------------------------------------------------"
    
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
source ./4make_vm_for_ha_test.sh
    make_utm_ha_test_vms $customer
fi    