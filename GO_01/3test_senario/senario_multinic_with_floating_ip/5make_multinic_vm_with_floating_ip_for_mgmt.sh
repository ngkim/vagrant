#!/bin/bash

vm_create_timeout=300
normal_timeout=60

make_user_singlenic_utm_vm()
{
    echo "
    ############################################################################
        utm vm 생성[mgmt nic 설정] !!!
    ############################################################################
    "

    vm=$1
    image=$2    
    mgmt_net=$3    
    zone=$4
    host=$5

    get_tenant_id _cust_tenant_id   $GUEST_TENANT_NAME
    get_image_id  _cust_image_id    $image

    get_net_id  _mgmt_net_id        $mgmt_net    

    echo '# --------------------------------------------------------------------'
    echo "  NET INFO "
    echo '# --------------------------------------------------------------------'
    printf "%20s[%20s] -> [%s] \n" MGMT_NET   $mgmt_net    $_mgmt_net_id
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
        --nic net-id=$_mgmt_net_id
        --availability-zone ${zone}:${host}
        --security-groups default
    "

    run_cli_as_user $cli    
    
    # 원래 admin 계정으로 환경변수 설정
    set_openstack_cli_admin_env
    
    if ! timeout $vm_create_timeout /bin/bash -c "while ! nova list --all-tenants | grep ${vm} | grep ACTIVE; do sleep 5; echo wait.. ; done"; 
    then
        echo "## Instance <$vm> failed to go active after $vm_create_timeout seconds"
        exit 1
    else
        echo        
        echo ">> Instance <$vm> created"
    fi    
    
}

make_user_multinic_nored_utm_vm()
{
    echo "
    ############################################################################
        utm vm 생성[green, orange, guest nic 설정] !!!
    ############################################################################
    "

    vm=$1
    image=$2    
    mgmt_net=$3
    green_net=$4
    orange_net=$5    
    zone=$6
    host=$7

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
    printf "%20s -> [%s] \n" MGMT_NET   $mgmt_net
    printf "%20s -> [%s] \n" GREEN_NET  $green_net
    printf "%20s -> [%s] \n" ORANGE_NET $orange_net        
    printf "%20s -> [%s] \n" ZONE       $zone
    printf "%20s -> [%s] \n" HOST       $host
    echo '# --------------------------------------------------------------------'

    get_tenant_id _cust_tenant_id   $GUEST_TENANT_NAME
    get_image_id  _cust_image_id    $image

    get_net_id  _mgmt_net_id        $mgmt_net    
    get_net_id  _green_net_id       $green_net
    get_net_id  _orange_net_id      $orange_net    

    echo '# --------------------------------------------------------------------'
    echo "  NET INFO "
    echo '# --------------------------------------------------------------------'
    printf "%20s[%20s] -> [%s] \n" MGMT_NET   $mgmt_net    $_mgmt_net_id    
    printf "%20s[%20s] -> [%s] \n" GREEN_NET  $green_net    $_green_net_id
    printf "%20s[%20s] -> [%s] \n" ORANGE_NET $orange_net   $_orange_net_id
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
        --nic net-id=$_mgmt_net_id
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
        echo "## Instance <$vm> failed to go active after $vm_create_timeout seconds"
        exit 1
    else
        echo        
        echo ">> Instance <$vm> created"
    fi    
    
}

make_user_multinic_nomgmt_utm_vm()
{
    echo "
    ############################################################################
        utm vm 생성[green, orange, red nic 설정] !!!
    ############################################################################
    "

    vm=$1
    image=$2
    red_net=$3
    green_net=$4
    orange_net=$5    
    zone=$6
    host=$7

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
    printf "%20s -> [%s] \n" ZONE       $zone
    printf "%20s -> [%s] \n" HOST       $host
    echo '# --------------------------------------------------------------------'

    get_tenant_id _cust_tenant_id   $GUEST_TENANT_NAME
    get_image_id  _cust_image_id    $image
    
    get_net_id  _red_net_id         $red_net
    get_net_id  _green_net_id       $green_net
    get_net_id  _orange_net_id      $orange_net    

    echo '# --------------------------------------------------------------------'
    echo "  NET INFO "
    echo '# --------------------------------------------------------------------'    
    printf "%20s[%20s] -> [%s] \n" RED_NET    $red_net      $_red_net_id
    printf "%20s[%20s] -> [%s] \n" GREEN_NET  $green_net    $_green_net_id
    printf "%20s[%20s] -> [%s] \n" ORANGE_NET $orange_net   $_orange_net_id
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
        echo "## Instance <$vm> failed to go active after $vm_create_timeout seconds"
        exit 1
    else
        echo        
        echo ">> Instance <$vm> created"
    fi    
    
}

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
    printf "%20s -> [%s] \n" MGMT_NET   $mgmt_net
    printf "%20s -> [%s] \n" GREEN_NET  $green_net
    printf "%20s -> [%s] \n" ORANGE_NET $orange_net
    printf "%20s -> [%s] \n" RED_NET    $red_net    
    printf "%20s -> [%s] \n" ZONE       $zone
    printf "%20s -> [%s] \n" HOST       $host
    echo '# --------------------------------------------------------------------'

    get_tenant_id _cust_tenant_id   $GUEST_TENANT_NAME
    get_image_id  _cust_image_id    $image

    get_net_id  _mgmt_net_id        $mgmt_net
    get_net_id  _red_net_id         $red_net
    get_net_id  _green_net_id       $green_net
    get_net_id  _orange_net_id      $orange_net    

    echo '# --------------------------------------------------------------------'
    echo "  NET INFO "
    echo '# --------------------------------------------------------------------'
    printf "%20s[%20s] -> [%s] \n" MGMT_NET   $mgmt_net    $_mgmt_net_id
    printf "%20s[%20s] -> [%s] \n" RED_NET    $red_net      $_red_net_id
    printf "%20s[%20s] -> [%s] \n" GREEN_NET  $green_net    $_green_net_id
    printf "%20s[%20s] -> [%s] \n" ORANGE_NET $orange_net   $_orange_net_id
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
        echo "## Instance <$vm> failed to go active after $vm_create_timeout seconds"
        exit 1
    else
        echo        
        echo ">> Instance <$vm> created"
    fi    
    
}

allocate_floating_ip_to_mgmt_vm() 
{
    vm_name=$1
    
    # nova floating-ip-list
    # nova floating-ip-create
    #   172.24.4.225 | None        | None     | public |
    # nova floating-ip-associate INSTANCE_NAME_OR_ID FLOATING_IP_ADDRESS 
    #   ex) nova floating-ip-associate VM1 172.24.4.225
    
    # 여러개의 IP를 갖는 VM에서 특정 IP에 floating ip를 할당할때     
    # $ nova floating-ip-associate --fixed-address FIXED_IP_ADDRESS 
    #    INSTANCE_NAME_OR_ID FLOATING_IP_ADDRESS

    # LJG: customer 계정으로 명령을 수행하기 위해 환경변수 설정
    set_openstack_cli_user_env
    
    echo `nova floating-ip-create $FLOATING_IP_POOL_NAME | grep $FLOATING_IP_POOL_NAME | cut -d '|' -f2`
    FLOATING_IP=`nova floating-ip-create $FLOATING_IP_POOL_NAME | grep $FLOATING_IP_POOL_NAME | cut -d '|' -f2`    
    echo "FLOATING_IP -> $FLOATING_IP"
    
    # list floating addresses
    if ! timeout 10 sh -c "while ! nova floating-ip-list | grep $FLOATING_IP_POOL_NAME | grep -q $FLOATING_IP; do sleep 1; echo wait.. ; done"; then
        echo "#Floating IP<$FLOATING_IP> not allocated"
        exit 1
    else
        echo           
        echo ">>Floating IP<$FLOATING_IP> allocated"
    fi
    
    cli="nova floating-ip-associate $vm_name $FLOATING_IP"
    run_cli_as_user $cli

    # test we can ping our floating ip within ASSOCIATE_TIMEOUT seconds
    if ! timeout $normal_timeout sh -c "while ! ping -c1 -w1 $FLOATING_IP; do sleep 1; echo wait.. ; done"; then
        echo "#Floating IP<$FLOATING_IP> ping fail !!!!"
        exit 1
    else
        echo        
        echo ">>Floating IP<$FLOATING_IP> ping success !!!!"
    fi
}