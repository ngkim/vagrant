#!/bin/bash

vm_create_timeout=300
normal_timeout=60


make_user_multinic_utm_vm()
{
    echo "
    ############################################################################
        utm vm 생성[green, orange, red, guest nic 설정] !!!
    ############################################################################
    "

    vm=$1
    image=$2    
    mgmt_net=$3
    red_net=$4
    green_net=$5
    orange_net=$6    
    zone=$7
    host=$8

    printf '# --------------------------------------------------------------------'
    printf "  CUSTOMER INFO "
    printf "%20s -> [%s] \n" GUEST_TENANT_NAME   $GUEST_TENANT_NAME
    printf "%20s -> [%s] \n" GUEST_USER_NAME     $GUEST_USER_NAME
    printf "%20s -> [%s] \n" GUEST_USER_PASS     $GUEST_USER_PASS
    printf '# --------------------------------------------------------------------'
    printf "  INPUT INFO "
    printf '# --------------------------------------------------------------------'
    printf "%20s -> [%s] \n" VM         $vm
    printf "%20s -> [%s] \n" IMAGE      $image
    printf "%20s -> [%s] \n" MGMT_NET   $mgmt_net
    printf "%20s -> [%s] \n" GREEN_NET  $green_net
    printf "%20s -> [%s] \n" ORANGE_NET $orange_net
    printf "%20s -> [%s] \n" RED_NET    $red_net    
    printf "%20s -> [%s] \n" ZONE       $zone
    printf "%20s -> [%s] \n" HOST       $host
    printf '# --------------------------------------------------------------------'

    get_tenant_id _cust_tenant_id   $GUEST_TENANT_NAME
    get_image_id  _cust_image_id    $image

    get_net_id  _mgmt_net_id        $mgmt_net
    get_net_id  _red_net_id         $red_net
    get_net_id  _green_net_id       $green_net
    get_net_id  _orange_net_id      $orange_net    

    printf '# --------------------------------------------------------------------'
    printf "  NET INFO "
    printf '# --------------------------------------------------------------------'
    printf "%20s[%20s] -> [%s] \n" MGMT_NET   $mgmt_net    $_mgmt_net_id
    printf "%20s[%20s] -> [%s] \n" RED_NET    $red_net      $_red_net_id
    printf "%20s[%20s] -> [%s] \n" GREEN_NET  $green_net    $_green_net_id
    printf "%20s[%20s] -> [%s] \n" ORANGE_NET $orange_net   $_orange_net_id
    printf '# --------------------------------------------------------------------'


    # LJG: customer 계정으로 명령을 수행하기 위해 환경변수 설정
    set_openstack_cli_user_env
    get_vm_id _vm_id $vm $GUEST_TENANT_NAME $GUEST_USER_NAME $GUEST_USER_PASS

    if [ $_vm_id ]; then
        printf '# ----------------------------------------------------------------'
        printf "  VM INFO "
        printf '# ----------------------------------------------------------------'
        printf "%20s[%20s] -> [%s] \n" VM  $vm    $_vm_id
        printf '# ----------------------------------------------------------------'
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
        --nic net-id=$_mgmt_net_id
        --nic net-id=$_red_net_id
        --nic net-id=$_green_net_id
        --nic net-id=$_orange_net_id
        --availability-zone ${zone}:${host}
        --security-groups default
    "

    run_cli_as_user $cli    
    
    # 원래 admin 계정으로 환경변수 설정
    set_openstack_cli_admin_env
    
    if ! timeout $vm_create_timeout /bin/bash -c "while ! nova list --all-tenants | grep ${vm} | grep ACTIVE; do sleep 5; echo wait.. ; done"; 
    then
        printf "## Instance <$vm> failed to go active after $vm_create_timeout seconds"
        exit 1
    else
        printf        
        printf ">> Instance <$vm> created"
    fi    
    
}