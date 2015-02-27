#!/bin/bash

# senario.txt 파일에 있는 내용을 실행한다.

customer=$1
if [[ -z "$customer" ]]; then
    echo "에려  :: customer 이름을 입력하세요!!!"
    echo "사용법:: run.sh customer_name ip_seed_num"
    echo "    예:: run.sh forbiz 5"
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
        - keypair/keypair.pub           ex)forbizkey/forbizkey.pub
        - security group(default)       ex)icmp, tcp(22,80,443,5001)
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
    3. 3make_default_network.sh
        - 일반적으로 클라우드에서 제공하는 network 환경을 제공한다.
        - guest_network         ex) forbiz_guest_net
        - guest_subnetwork      ex) forbiz_guest_subnet
        - guest_router          ex) forbiz_guest_router
        - guest_router에 guest_subnetwork interface 연결
        - guest_router에 public gateway 설정
--------------------------------------------------------------------------------"
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
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
fi

echo "
--------------------------------------------------------------------------------
    4. 4make_hybrid_network.sh
        - UTM 테스트를 위한 hybrid network 환경을 제공한다.
        - green_network         ex) forbiz_green_net
        - green_subnetwork      ex) forbiz_green_subnet
        - orange_network        ex) forbiz_orange_net
        - orange_subnetwork     ex) forbiz_orange_subnet
--------------------------------------------------------------------------------"
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
source ./4make_hybrid_network.sh
    make_user_hybrid_green_network
    echo
    make_user_hybrid_green_subnet
    echo
    make_user_hybrid_orange_network
    echo
    make_user_hybrid_orange_subnet
    echo
fi

seed_num=$2
if [[ -z "$seed_num" ]]; then
    echo "에려  :: ip seed number룰 입력하세요!!!"
    echo "사용법:: run.sh customer_name ip_seed_num"
    exit
fi

echo "
--------------------------------------------------------------------------------
    5. 5make_vm_for_test.sh    
            
    - UTM 테스트를 위한 vm들을 만든다
    
        - UTM VM 생성
            - global_mgmt, green, orange, red 4개의 nic 을 갖는다.
            - all_in_one 서버에 생성한다.        
            - UTM 프로그램이 동작(Firewall, NAT 등)
            - bridge를 이용하여 eth1(green)과 eth2(orange)를 연결한다

        - Green 고객 클라이언트 VM 생성
            - global_mgmt, green 2개의 nic 을 갖는다.
            - cnode02 서버에 생성한다.
            - UTM VM을 gateway로 설정한다.(불필요)
            - UTM VM을 통해 고객 서버 VM에 통신한다. (iperf client 이용)
            - UTM VM을 통해 외부 서버에 통신한다. (youtube, naver 등등) -> 이건 나중에
            
        - Orange 고객 서버 VM 생성
        
           - LJG: green과 동일대역을 사용하므로 ip가 중복되는 경향이 많으므로
                  fixed ip를 할당하여 VM을 생성해야 하고 
                  이를 user_data에 동적으로 반영해야 한다.

            - global_mgmt, orange 2개의 nic 을 갖는다.
            - cnode02 서버에 생성한다.
            - UTM VM을 gateway로 설정한다.(불필요)
            - UTM VM을 통해 고객 클라이언트 VM에 통신한다. (iperf server 이용)
            - UTM VM을 통해 외부 서버에 통신한다. (wget, apt-get등 실행) -> 이건 나중에
--------------------------------------------------------------------------------"
    
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
source ./5make_vm_for_ha_test.sh
    make_utm_test_vms $customer $seed_num
fi    