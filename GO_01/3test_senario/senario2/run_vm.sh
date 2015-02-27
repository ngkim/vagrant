#!/bin/bash

# senario.txt 파일에 있는 내용을 실행한다.

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

# get_max_ip_seed_num seed_num

seed_num=40
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

utm_bootstrap_file="./bootstrap/utm_bootstrap_file"
green_bootstrap_file="./bootstrap/green_bootstrap_file"
orange_bootstrap_file="./bootstrap/orange_bootstrap_file"

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

ask_continue_stop

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



cmt() {
    
    make_user_green_vm_with_fixed_ip ${customer}_client $SERVER_IMAGE \
        $green_mgmt_ip  global_mgmt_net global_mgmt_subnet \
        $green_ip $GREEN_NET $GREEN_SUBNET \
        $AVAILABILITY_ZONE $CNODE02 $green_bootstrap_file
    
    sleep 3
    
    make_user_orange_vm_with_fixed_ip ${customer}_server $SERVER_IMAGE \
        $orange_mgmt_ip  global_mgmt_net global_mgmt_subnet \
        $orange_ip $ORANGE_NET $ORANGE_SUBNET \
        $AVAILABILITY_ZONE $CNODE02 $orange_bootstrap_file
    
    sleep 3
    
    make_user_utm_vm_with_fixed_ip ${customer}_utm $SERVER_IMAGE \
        $utm_mgmt_ip  global_mgmt_net global_mgmt_subnet \
        $utm_green_ip  $GREEN_NET $GREEN_SUBNET \
        $utm_orange_ip $ORANGE_NET $ORANGE_SUBNET \
        $AVAILABILITY_ZONE $CNODE02 $utm_bootstrap_file
    
}

source ./5make_vm_for_test.sh    
    
    make_user_utm_vm_with_fixed_ip ${customer}_utm $SERVER_IMAGE \
        $utm_mgmt_ip  global_mgmt_net global_mgmt_subnet \
        $utm_green_ip  $GREEN_NET $GREEN_SUBNET \
        $utm_orange_ip $ORANGE_NET $ORANGE_SUBNET \
        $AVAILABILITY_ZONE $CNODE01 $utm_bootstrap_file