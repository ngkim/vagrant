#!/bin/bash

echo "
################################################################################
#
#   make forbiz vms
#    endian VM          : guest_nic, green_nic, orange_nic, red_nic, floating-ip
#    green_client VM    : guest_nic, green_nic, floating-ip
#    orange_server VM   : guest_nic, orange_nic, floating-ip
#
################################################################################
"


function make_port() {

    # usage: make_port _port_id ip net_name subnet_name
    #        echo "result -> <$_port_id>"

    local _result_ptr=$1

    ip=$2
    net_name=$3
    subnet_name=$4  
    
    echo
    echo
    echo "#########################################################################"
    echo "inside make_port"
    echo "  ip          <$ip>"
    echo "  net_name    <$net_name>"
    echo "  subnet_name <$subnet_name>"
    echo "#########################"
    
    get_net_id _net_id $net_name
    get_subnet_id _subnet_id admin $subnet_name
    
        
    cli="neutron port-create --fixed-ip subnet_id=${_subnet_id},ip_address=${ip} ${net_id}"
    run_cli_as_user $cli        
    port_id=$(neutron port-list | grep $_subnet_id |grep $ip | awk '{print $2}')   
    printf "net_name[%s], subnet_name[%s], ip[%s] -> port_id[%s]\n" $net_name $subnet_name $ip $port_id

    eval $_result_ptr=$port_id
    echo "#########################################################################"

}

make_user_utm_vm()
{
    echo "
    ############################################################################
        utm vm 생성[green, orange, red, guest nic 설정] !!!
    ############################################################################
    "

    vm=$1
    image=$2
    guest_net=$3
    green_net=$4
    orange_net=$5
    red_net=$6
    zone=$7
    host=$8
    user_data_file=$9

    echo '# --------------------------------------------------------------------'
    echo "  CUSTOMER INFO "
    printf "%20s -> [%s] \n" GUEST_TENANT_NAME   $GUEST_TENANT_NAME
    printf "%20s -> [%s] \n" GUEST_USER_NAME     $GUEST_USER_NAME
    printf "%20s -> [%s] \n" GUEST_USER_PASS     $GUEST_USER_PASS
    echo '# --------------------------------------------------------------------'
    echo "  INPUT INFO "
    echo '# --------------------------------------------------------------------'
    printf "%20s -> [%s] \n" VM         $vm
    printf "%20s -> [%s] \n" IMAGE      $image
    printf "%20s -> [%s] \n" GREEN_NET  $green_net
    printf "%20s -> [%s] \n" ORANGE_NET $orange_net
    printf "%20s -> [%s] \n" RED_NET    $red_net
    printf "%20s -> [%s] \n" GUEST_NET  $guest_net
    printf "%20s -> [%s] \n" ZONE       $zone
    printf "%20s -> [%s] \n" HOST       $host
    echo '# --------------------------------------------------------------------'

    get_tenant_id _cust_tenant_id $GUEST_TENANT_NAME
    get_image_id  _cust_image_id  $image

    get_net_id  _green_net_id      $green_net
    get_net_id  _orange_net_id     $orange_net
    get_net_id  _red_net_id        $red_net
    get_net_id  _guest_net_id      $guest_net

    echo '# --------------------------------------------------------------------'
    echo "  NET INFO "
    echo '# --------------------------------------------------------------------'
    printf "%20s[%20s] -> [%s] \n" GREEN_NET  $green_net    $_green_net_id
    printf "%20s[%20s] -> [%s] \n" ORANGE_NET $orange_net   $_orange_net_id
    printf "%20s[%20s] -> [%s] \n" RED_NET    $red_net      $_red_net_id
    printf "%20s[%20s] -> [%s] \n" GUEST_NET  $guest_net    $_guest_net_id
    echo '# --------------------------------------------------------------------'


    # LJG: customer 계정으로 명령을 수행하기 위해 환경변수 설정
    set_openstack_cli_user_env
    get_vm_id _vm_id $vm $GUEST_TENANT_NAME $GUEST_USER_NAME $GUEST_USER_PASS

    if [ $_vm_id ]; then
        echo '# ----------------------------------------------------------------'
        echo "  VM INFO "
        echo '# ----------------------------------------------------------------'
        printf "%20s[%20s] -> [%s] \n" VM  $vm    $_vm_id
        echo '# ----------------------------------------------------------------'
	    printf "%s vm already exists so delete it !!!\n" $vm
	    cli="nova delete $vm"
	    run_cli_as_user $cli
    fi

    # LJG: red는 현재 ip가 부족해서 나중에 지원 --nic net-id=$_red_net_id
    cli="
    nova boot $vm
        --flavor 3
        --image $image
        --key-name $GUEST_KEY
        --nic net-id=$_guest_net_id
        --nic net-id=$_green_net_id
        --nic net-id=$_orange_net_id
        --availability-zone ${zone}:${host}
        --security-groups default
        --user-data $user_data_file
    "

    run_cli_as_user $cli

    # 원래 admin 계정으로 환경변수 설정
    set_openstack_cli_admin_env

}


make_user_utm_vm_with_fixed_ip()
{
    echo "
    ############################################################################
        utm vm 생성(with fixed ip)[green, guest nic 설정] !!!
    ############################################################################
    "    
    
    vm=$1
    image=$2
    
    guest_ip=$3
    guest_net=$4
    guest_subnet=$5
    
    green_ip=$6
    green_net=$7
    green_subnet=$8
    
    orange_ip=$9
    orange_net=${10}
    orange_subnet=${11}
    
    zone=${12}
    host=${13}
    user_data_file=${14}

    echo '# --------------------------------------------------------------------'
    echo "  CUSTOMER INFO "
    printf "%20s -> [%s] \n" GUEST_TENANT_NAME   $GUEST_TENANT_NAME
    printf "%20s -> [%s] \n" GUEST_USER_NAME     $GUEST_USER_NAME
    printf "%20s -> [%s] \n" GUEST_USER_PASS     $GUEST_USER_PASS
    echo '# --------------------------------------------------------------------'
    echo "  INPUT INFO "
    echo '# --------------------------------------------------------------------'
    printf "%20s -> [%s] \n" VM             $vm
    printf "%20s -> [%s] \n" IMAGE          $image
    printf "%20s -> [%s] \n" GUEST_IP       $guest_ip
    printf "%20s -> [%s] \n" GUEST_NET      $guest_net
    printf "%20s -> [%s] \n" GUEST_SUBNET   $guest_subnet
    printf "%20s -> [%s] \n" GREEN_IP       $green_ip
    printf "%20s -> [%s] \n" GREEN_NET      $green_net
    printf "%20s -> [%s] \n" GREEN_SUBNET   $green_subnet
    printf "%20s -> [%s] \n" ORANGE_IP      $orange_ip
    printf "%20s -> [%s] \n" ORANGE_NET     $orange_net
    printf "%20s -> [%s] \n" ORANGE_SUBNET  $orange_subnet
    printf "%20s -> [%s] \n" ZONE           $zone
    printf "%20s -> [%s] \n" HOST           $host
    printf "%20s -> [%s] \n" USERDATA       $user_data_file
    echo '# --------------------------------------------------------------------'    

    
    get_tenant_id _cust_tenant_id $GUEST_TENANT_NAME
    get_image_id  _cust_image_id  $image

    make_port guest_port_id  $guest_ip  $guest_net  $guest_subnet    
    make_port green_port_id  $green_ip  $green_net  $green_subnet
    make_port orange_port_id $orange_ip $orange_net $orange_subnet

    # LJG: customer 계정으로 명령을 수행하기 위해 환경변수 설정
    set_openstack_cli_user_env

    get_vm_id _vm_id $vm $GUEST_TENANT_NAME $GUEST_USER_NAME $GUEST_USER_PASS

    if [ $_vm_id ]; then
        echo '# ----------------------------------------------------------------'
        echo "  VM INFO "
        echo '# ----------------------------------------------------------------'
        printf "%20s[%20s] -> [%s] \n" VM  $vm    $_vm_id
        echo '# ----------------------------------------------------------------'
        printf "%s vm already exists so delete it !!!\n" $vm
        cli="nova delete $vm"
        run_cli_as_user $cli
    fi
    
    
    cli="
    nova boot $vm
        --flavor 3
        --image $image
        --key-name $GUEST_KEY        
        --nic port-id=$guest_port_id
        --nic port-id=$green_port_id
        --nic port-id=$orange_port_id
        --availability-zone ${zone}:${host}
        --security-groups default
        --user-data $user_data_file
    "

    run_cli_as_user $cli

    # 원래 admin 계정으로 환경변수 설정
    set_openstack_cli_admin_env
}

make_user_green_vm()
{
    echo "
    ############################################################################
        green customer vm 생성[green, guest nic 설정] !!!
    ############################################################################
    "

    vm=$1
    image=$2
    guest_net=$3
    green_net=$4    
    zone=$5
    host=$6
    user_data_file=$7

    echo '# --------------------------------------------------------------------'
    echo "  CUSTOMER INFO "
    echo '# --------------------------------------------------------------------'
    printf "%20s -> [%s] \n" GUEST_TENANT_NAME   $GUEST_TENANT_NAME
    printf "%20s -> [%s] \n" GUEST_USER_NAME     $GUEST_USER_NAME
    printf "%20s -> [%s] \n" GUEST_USER_PASS     $GUEST_USER_PASS
    echo '# --------------------------------------------------------------------'
    echo "  INPUT INFO "
    echo '# --------------------------------------------------------------------'
    printf "%20s -> [%s] \n" VM         $vm
    printf "%20s -> [%s] \n" IMAGE      $image
    printf "%20s -> [%s] \n" GREEN_NET  $green_net
    printf "%20s -> [%s] \n" GUEST_NET  $guest_net
    printf "%20s -> [%s] \n" ZONE       $zone
    printf "%20s -> [%s] \n" HOST       $host
    echo '# --------------------------------------------------------------------'

    get_tenant_id _cust_tenant_id $GUEST_TENANT_NAME
    get_image_id  _cust_image_id  $image

    get_net_id _green_net_id $green_net
    get_net_id _guest_net_id $guest_net

    echo '# --------------------------------------------------------------------'
    echo "  NET INFO "
    echo '# --------------------------------------------------------------------'
    printf "%20s[%20s] -> [%s] \n" GREEN_NET  $green_net    $_green_net_id
    printf "%20s[%20s] -> [%s] \n" GUEST_NET  $guest_net    $_guest_net_id
    echo '# --------------------------------------------------------------------'

    # LJG: customer 계정으로 명령을 수행하기 위해 환경변수 설정
    set_openstack_cli_user_env

    get_vm_id _vm_id $vm

    if [ $_vm_id ]; then
        echo '# ----------------------------------------------------------------'
        echo "  VM INFO "
        echo '# ----------------------------------------------------------------'
        printf "%20s[%20s] -> [%s] \n" VM  $vm    $_vm_id
        echo '# ----------------------------------------------------------------'
        printf "%s vm already exists so delete it !!!\n" $vm
        cli="nova delete $vm"
        run_cli_as_user $cli
    fi

    cli="
    nova boot $vm
        --flavor 3
        --image $image
        --key-name $GUEST_KEY
        --nic net-id=$_guest_net_id        
        --nic net-id=$_green_net_id
        --availability-zone ${zone}:${host}
        --security-groups default
        --user-data $user_data_file
    "
    run_cli_as_user $cli

    # 원래 admin 계정으로 환경변수 설정
    set_openstack_cli_admin_env

}


make_user_green_vm_with_fixed_ip()
{
    echo "
    ############################################################################
    green client vm 생성(with fixed ip)[green, guest nic 설정] !!!
    ############################################################################
    "

    vm=$1
    image=$2
    guest_ip=$3
    guest_net=$4
    guest_subnet=$5
    green_ip=$6
    green_net=$7
    green_subnet=$8
    zone=$9
    host=${10}
    user_data_file=${11}

    echo '# --------------------------------------------------------------------'
    echo "  CUSTOMER INFO "
    printf "%20s -> [%s] \n" GUEST_TENANT_NAME   $GUEST_TENANT_NAME
    printf "%20s -> [%s] \n" GUEST_USER_NAME     $GUEST_USER_NAME
    printf "%20s -> [%s] \n" GUEST_USER_PASS     $GUEST_USER_PASS
    echo '# --------------------------------------------------------------------'
    echo "  INPUT INFO "
    echo '# --------------------------------------------------------------------'
    printf "%20s -> [%s] \n" VM             $vm
    printf "%20s -> [%s] \n" IMAGE          $image
    printf "%20s -> [%s] \n" GUEST_IP       $guest_ip
    printf "%20s -> [%s] \n" GUEST_NET      $guest_net
    printf "%20s -> [%s] \n" GUEST_SUBNET   $guest_subnet
    printf "%20s -> [%s] \n" GREEN_IP       $green_ip
    printf "%20s -> [%s] \n" GREEN_NET      $green_net
    printf "%20s -> [%s] \n" GREEN_SUBNET   $green_subnet
    printf "%20s -> [%s] \n" ZONE           $zone
    printf "%20s -> [%s] \n" HOST           $host
    printf "%20s -> [%s] \n" USERDATA       $user_data_file
    echo '# --------------------------------------------------------------------'
    
    get_tenant_id _cust_tenant_id $GUEST_TENANT_NAME
    get_image_id  _cust_image_id  $image

    make_port guest_port_id  $guest_ip  $guest_net  $guest_subnet
    make_port green_port_id $green_ip $green_net $green_subnet   
    
    # LJG: customer 계정으로 명령을 수행하기 위해 환경변수 설정
    set_openstack_cli_user_env

    get_vm_id _vm_id $vm $GUEST_TENANT_NAME $GUEST_USER_NAME $GUEST_USER_PASS

    if [ $_vm_id ]; then
        echo '# ----------------------------------------------------------------'
        echo "  VM INFO "
        echo '# ----------------------------------------------------------------'
        printf "%20s[%20s] -> [%s] \n" VM  $vm    $_vm_id
        echo '# ----------------------------------------------------------------'
        printf "%s vm already exists so delete it !!!\n" $vm
        cli="nova delete $vm"
        run_cli_as_user $cli
    fi     
    
    cli="
    nova boot $vm
        --flavor 3
        --image $image
        --key-name $GUEST_KEY        
        --nic port-id=$guest_port_id
        --nic port-id=$green_port_id
        --availability-zone ${zone}:${host}
        --security-groups default
        --user-data $user_data_file
    "

    run_cli_as_user $cli

    # 원래 admin 계정으로 환경변수 설정
    set_openstack_cli_admin_env
}


make_user_orange_vm()
{
    echo "
    ############################################################################
        orange server vm 생성[orange, guest nic 설정] !!!
    ############################################################################
    "

    vm=$1
    image=$2
    guest_net=$3
    orange_net=$4
    zone=$5
    host=$6
    user_data_file=$7

    echo '# --------------------------------------------------------------------'
    echo "  CUSTOMER INFO "
    printf "%20s -> [%s] \n" GUEST_TENANT_NAME   $GUEST_TENANT_NAME
    printf "%20s -> [%s] \n" GUEST_USER_NAME     $GUEST_USER_NAME
    printf "%20s -> [%s] \n" GUEST_USER_PASS     $GUEST_USER_PASS
    echo '# --------------------------------------------------------------------'
    echo "  INPUT INFO "
    echo '# --------------------------------------------------------------------'
    printf "%20s -> [%s] \n" VM         $vm
    printf "%20s -> [%s] \n" IMAGE      $image
    printf "%20s -> [%s] \n" ORANGE_NET $orange_net
    printf "%20s -> [%s] \n" GUEST_NET  $guest_net
    printf "%20s -> [%s] \n" ZONE       $zone
    printf "%20s -> [%s] \n" HOST       $host
    echo '# --------------------------------------------------------------------'

    get_tenant_id _cust_tenant_id $GUEST_TENANT_NAME
    get_image_id  _cust_image_id  $image

    get_net_id _orange_net_id     $orange_net
    get_net_id _guest_net_id      $guest_net

    echo '# --------------------------------------------------------------------'
    echo "  NET INFO "
    echo '# --------------------------------------------------------------------'
    printf "%20s[%20s] -> [%s] \n" ORANGE_NET $orange_net   $_orange_net_id
    printf "%20s[%20s] -> [%s] \n" GUEST_NET  $guest_net    $_guest_net_id
    echo '# --------------------------------------------------------------------'


    # LJG: customer 계정으로 명령을 수행하기 위해 환경변수 설정
    set_openstack_cli_user_env

    get_vm_id _vm_id $vm $GUEST_TENANT_NAME $GUEST_USER_NAME $GUEST_USER_PASS

    if [ $_vm_id ]; then
        echo '# ----------------------------------------------------------------'
        echo "  VM INFO "
        echo '# ----------------------------------------------------------------'
        printf "%20s[%20s] -> [%s] \n" VM  $vm    $_vm_id
        echo '# ----------------------------------------------------------------'
        printf "%s vm already exists so delete it !!!\n" $vm
        cli="nova delete $vm"
        run_cli_as_user $cli
    fi

    cli="
    nova boot $vm
        --flavor 3
        --image $image
        --key-name $GUEST_KEY        
        --nic net-id=$_guest_net_id
        --nic net-id=$_orange_net_id
        --availability-zone ${zone}:${host}
        --security-groups default
        --user-data $user_data_file
    "

    run_cli_as_user $cli

    # 원래 admin 계정으로 환경변수 설정
    set_openstack_cli_admin_env
}


make_user_orange_vm_with_fixed_ip()
{
    echo "
    ############################################################################
        orange server vm 생성(with fixed ip)[orange, guest nic 설정] !!!
    ############################################################################
    "

    vm=$1
    image=$2
    guest_ip=$3
    guest_net=$4
    guest_subnet=$5
    orange_ip=$6
    orange_net=$7
    orange_subnet=$8
    zone=$9
    host=${10}
    user_data_file=${11}

    echo '# --------------------------------------------------------------------'
    echo "  CUSTOMER INFO "
    printf "%20s -> [%s] \n" GUEST_TENANT_NAME   $GUEST_TENANT_NAME
    printf "%20s -> [%s] \n" GUEST_USER_NAME     $GUEST_USER_NAME
    printf "%20s -> [%s] \n" GUEST_USER_PASS     $GUEST_USER_PASS
    echo '# --------------------------------------------------------------------'
    echo "  INPUT INFO "
    echo '# --------------------------------------------------------------------'
    printf "%20s -> [%s] \n" VM             $vm
    printf "%20s -> [%s] \n" IMAGE          $image
    printf "%20s -> [%s] \n" GUEST_IP       $guest_ip
    printf "%20s -> [%s] \n" GUEST_NET      $guest_net
    printf "%20s -> [%s] \n" GUEST_SUBNET   $guest_subnet
    printf "%20s -> [%s] \n" ORANGE_IP      $orange_ip
    printf "%20s -> [%s] \n" ORANGE_NET     $orange_net
    printf "%20s -> [%s] \n" ORANGE_SUBNET  $orange_subnet
    printf "%20s -> [%s] \n" ZONE           $zone
    printf "%20s -> [%s] \n" HOST           $host
    printf "%20s -> [%s] \n" USERDATA       $user_data_file
    echo '# --------------------------------------------------------------------'    

    get_tenant_id _cust_tenant_id $GUEST_TENANT_NAME
    get_image_id  _cust_image_id  $image

    make_port guest_port_id  $guest_ip  $guest_net  $guest_subnet
    make_port orange_port_id $orange_ip $orange_net $orange_subnet
    
    # LJG: customer 계정으로 명령을 수행하기 위해 환경변수 설정
    set_openstack_cli_user_env

    get_vm_id _vm_id $vm $GUEST_TENANT_NAME $GUEST_USER_NAME $GUEST_USER_PASS

    if [ $_vm_id ]; then
        echo '# ----------------------------------------------------------------'
        echo "  VM INFO "
        echo '# ----------------------------------------------------------------'
        printf "%20s[%20s] -> [%s] \n" VM  $vm    $_vm_id
        echo '# ----------------------------------------------------------------'
        printf "%s vm already exists so delete it !!!\n" $vm
        cli="nova delete $vm"
        run_cli_as_user $cli
    fi    
    
    cli="
    nova boot $vm
        --flavor 3
        --image $image
        --key-name $GUEST_KEY        
        --nic port-id=$guest_port_id
        --nic port-id=$orange_port_id
        --availability-zone ${zone}:${host}
        --security-groups default
        --user-data $user_data_file
    "

    run_cli_as_user $cli

    # 원래 admin 계정으로 환경변수 설정
    set_openstack_cli_admin_env
}

function make_utm_test_vms() {
    
    customer=$1
    seed_num=$2
    
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

    make_user_green_vm_with_fixed_ip ${customer}_client $SERVER_IMAGE \
        $green_mgmt_ip  global_mgmt_net global_mgmt_subnet \
        $green_ip $GREEN_NET $GREEN_SUBNET \
        $AVAILABILITY_ZONE $CNODE02 $green_bootstrap_file
    
    sleep 2
    
    make_user_orange_vm_with_fixed_ip ${customer}_server $SERVER_IMAGE \
        $orange_mgmt_ip  global_mgmt_net global_mgmt_subnet \
        $orange_ip $ORANGE_NET $ORANGE_SUBNET \
        $AVAILABILITY_ZONE $CNODE02 $orange_bootstrap_file
    
    sleep 2
    
    make_user_utm_vm_with_fixed_ip ${customer}_utm $SERVER_IMAGE \
        $utm_mgmt_ip  global_mgmt_net global_mgmt_subnet \
        $utm_green_ip  $GREEN_NET $GREEN_SUBNET \
        $utm_orange_ip $ORANGE_NET $ORANGE_SUBNET \
        $AVAILABILITY_ZONE $CNODE01 $utm_bootstrap_file
    
    
}
    

# NIC 설정
# ifconfig eth0 10.0.0.102 netmask 255.255.255.0 up
# ifconfig eth1 211.224.204.157 netmask 255.255.255.224 up
# ifconfig eth3 0.0.0.0 up
# ifconfig eth5 0.0.0.0 up
 
# public nic에 default gw 설정
# route add default gw 211.224.204.129 dev eth1
 
# dns 설정
# nameserver 8.8.8.8 | tee -a /etc/resolv.conf
