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

source ./4make_hybrid_network.sh
    make_user_hybrid_green_network
    echo
    make_user_hybrid_green_subnet
    echo
    make_user_hybrid_orange_network
    echo
    make_user_hybrid_orange_subnet
    echo

seed_num=$2
if [[ -z "$seed_num" ]]; then
    echo "에려  :: ip seed number룰 입력하세요!!!"
    echo "사용법:: run.sh customer_name ip_seed_num"
    exit
fi

source ./5make_vm_for_ha_test.sh    
    
    let "mgmt_base=seed_num+5"
    let "green_base=seed_num+5"
    let "orange_base=seed_num+106"    
    
    utm_mgmt_ip="10.10.10.${mgmt_base}"
    let "mgmt_base+=1"
    green_mgmt_ip="10.10.10.${mgmt_base}"
    let "mgmt_base+=1"
    orange_mgmt_ip="10.10.10.${mgmt_base}"
    
    utm_green_ip="192.168.0.${green_base}"
    let "green_base+=1"
    green_ip="192.168.0.${green_base}"
    
    utm_orange_ip="192.168.0.${orange_base}"
    let "orange_base+=1"
    orange_ip="192.168.0.${orange_base}"    
    
    utm_template_file="./template/utm_bootstrap_template.sh"
    green_template_file="./template/green_bootstrap_template.sh"
    orange_template_file="./template/orange_bootstrap_template.sh"
    
    utm_bootstrap_file="./bootstrap/utm_bootstrap_file_${utm_mgmt_ip}"
    green_bootstrap_file="./bootstrap/green_bootstrap_file_${green_mgmt_ip}"
    orange_bootstrap_file="./bootstrap/orange_bootstrap_file_${orange_mgmt_ip}"
    
    printf "# ---------------------------------------------------------------------\n"
    printf "%-30s => %s  \n" green_bootstrap_file   $green_bootstrap_file
    printf "%-30s => %s  \n" orange_bootstrap_file  $orange_bootstrap_file
    printf "# ---------------------------------------------------------------------\n"
    printf "%-30s => %s  \n" green_template_file    $green_template_file
    printf "%-30s => %s  \n" orange_template_file   $orange_template_file
    printf "# ---------------------------------------------------------------------\n"
    printf "%-30s => %s  \n" utm_mgmt_ip    $utm_mgmt_ip
    printf "%-30s => %s  \n" green_mgmt_ip  $green_mgmt_ip
    printf "%-30s => %s  \n" orange_mgmt_ip $orange_mgmt_ip
    printf "%-30s => %s  \n" utm_green_ip   $utm_green_ip
    printf "%-30s => %s  \n" green_ip       $green_ip
    printf "%-30s => %s  \n" utm_orange_ip  $utm_orange_ip
    printf "%-30s => %s  \n" orange_ip      $orange_ip
    printf "# ---------------------------------------------------------------------\n"    
    
    source $utm_template_file    $utm_bootstrap_file    $utm_green_ip 255.255.255.0
    source $green_template_file  $green_bootstrap_file  eth1 $green_ip 255.255.255.0 $oragne_ip
    source $orange_template_file $orange_bootstrap_file eth1 $orange_ip 255.255.255.0
    
    printf "# ---------------------------------------------------------------------\n"
    cat $green_bootstrap_file
    printf "# ---------------------------------------------------------------------\n"
    cat $orange_bootstrap_file
    printf "# ---------------------------------------------------------------------\n"
    cat $utm_bootstrap_file
    printf "# ---------------------------------------------------------------------\n"    
    
    make_user_utm_vm_with_fixed_ip ${customer}_utm_m $SERVER_IMAGE \
        $utm_mgmt_ip  global_mgmt_net global_mgmt_subnet \
        $utm_green_ip  $GREEN_NET $GREEN_SUBNET \
        $utm_orange_ip $ORANGE_NET $ORANGE_SUBNET \
        $AVAILABILITY_ZONE $CNODE01 $utm_bootstrap_file