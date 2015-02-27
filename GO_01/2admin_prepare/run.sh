#!/bin/bash

set -o errexit

# _senario.txt 파일에 있는 내용을 실행한다.

echo "##########################################################################"    
echo "(#) 프로그램 설명"
echo "##########################################################################"    
cat ./_senario.txt | more
echo "##########################################################################"    

source ./common_env
source ./common_lib

echo "
--------------------------------------------------------------------------------
    1. 1make_admin_security_and_keypair.sh    
    - host-aggr기능을 이용하여 available-zone을 생성한다.
        - HOST_AGGR_NAME    ex) zo-aggr
        - AVAILABILITY_ZONE ex)seocho-az
        - HOST              ex) controller, cnode01, cnode02
    - admin default security group에 rule을 추가한다.
        - security gropu(default)       ex)icmp, tcp(22,80,443,5001)
    - keypair을 생성한다.                
        - admin keypair/keypair.pub     ex)adminkey/admin.pub
--------------------------------------------------------------------------------"
           
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
source ./1make_admin_base_setting.sh    
    admin_default_security_group
    add_ssh_pool_security_group    
    admin_keypair
    host_aggregate    
    echo
fi



echo "
--------------------------------------------------------------------------------
    2. 2change_admin_quota.sh    
    - admin Quota를 적절하게 조정한다.(기본적으로 10배씩 증가시킴)
        - nova      ex) instances 100/cores 200/ram 512000/floating-ips 100/metadata_items 1280/injected_files 50
        - neutron   ex) floatingip 500/network 100/port 5000/router 100/security_group 100/security_group_rule 1000 
        - cinder    ex) gigabytes 10000/snapshots 100/volumes 100
--------------------------------------------------------------------------------"
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then

source ./2change_admin_quota.sh
    update_admin_nova_quota
    echo
    update_admin_neutron_quota
    echo
    update_admin_cinder_quota
    echo
fi

                        
echo "
--------------------------------------------------------------------------------
    3. 3make_base_public_network.sh    
    - public provider network을 flat mode로 제공한다.
        - public_network        ex) public_net                  
        - public_subnetwork     ex) public_subnet
            cidr: 221.145.180.64/26 
            gw:   221.145.180.65
            ip-pool:221.145.180.71~85(east)
            ip-pool:221.145.180.86~95(west)
        
--------------------------------------------------------------------------------"
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
source ./3make_base_public_network.sh
    make_public_network
    echo
    make_public_sub_network
    echo
fi


                

echo "
--------------------------------------------------------------------------------
    4. 4make_global_mgmt_network.sh
    - UTM 테스트를 위해 접근하기 용이한 global mgmt network 환경을 제공한다
        - 테스트를 위해 대상이 되는 모든 VM은 global_mgmt_network에 연결한다.
        - admin계정으로 test_controller VM을 만들고 
          이를 기반으로 다양한 test_vm에 접속하여test 명령을 수행한다.    
--------------------------------------------------------------------------------"                
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
source ./4make_global_mgmt_network.sh
	make_mgmt_network
	echo
	make_mgmt_subnet
	echo
	make_mgmt_router
	echo
	add_mgmt_subnet_interface_to_mgmt_router
	echo
	set_external_gateway_to_mgmt_router
	echo
fi

echo "
--------------------------------------------------------------------------------
    6. 6make_base_images
    - 보편적으로 사용될 이미지들을 설치한다.
    
--------------------------------------------------------------------------------"
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
source ./6make_base_images.sh
    install_base_images
fi

echo "
--------------------------------------------------------------------------------
    7. 7make_db_util_views
    - 오픈스택을 분석하는 데이터베이스 뷰들을 생성한다.
    	vw_vm_trace, vw_vm_inventory
    
--------------------------------------------------------------------------------"
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
source ./7make_db_views.sh
    create_openstack_db_views
fi


echo "
--------------------------------------------------------------------------------
    8. 8make_global_mgmt_vm.sh
    - admin 계정으로 global_mgmt_network에 연결된 모든 vm에 접속할 수 있는 
      vm을 만들고 외부접속을 위해 floating ip를 할당한다.
       
        - global_mgmt_net에 vm(global_mgmt_vm)을 생성한다.
        - global_mgmt_vm에 floating_ip를 할당한다.
    
--------------------------------------------------------------------------------"
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
source ./8make_global_mgmt_vm.sh	    
    #make_global_mgmt_vm gmgmt_vm ubuntu-12.04 ssh_pool seocho-az cnode01    
    # allocate_floating_ip gmgmt_vm global_mgmt_net
    
    #make_global_mgmt_vm gmgmt_vm ubuntu-12.04 ssh_pool seocho-az cnode01 ./81global_mgmt_vm_template.sh
    #allocate_floating_ip_to_mgmt_vm gmgmt_vm  
	    	    
	make_global_mgmt_vm gmgmt_vm trusty-image ssh_pool daejon-az anode ./81global_mgmt_vm_template.sh
fi