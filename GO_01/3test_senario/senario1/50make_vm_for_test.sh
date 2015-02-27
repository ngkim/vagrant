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
    "
    # --user-data $user_data_file

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

# NIC 설정
# ifconfig eth0 10.0.0.102 netmask 255.255.255.0 up
# ifconfig eth1 211.224.204.157 netmask 255.255.255.224 up
# ifconfig eth3 0.0.0.0 up
# ifconfig eth5 0.0.0.0 up
 
# public nic에 default gw 설정
# route add default gw 211.224.204.129 dev eth1
 
# dns 설정
# nameserver 8.8.8.8 | tee -a /etc/resolv.conf
