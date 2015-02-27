#!/bin/bash

echo "
################################################################################
#
#   make vm on Private Network Test
#
################################################################################
"

source ./common_env
source ./common_lib

vm_create_timeout=300
normal_timeout=60

make_global_mgmt_vm()
{
    echo '
    ################################################################################
        global mgmt vm 생성 !!!
    ################################################################################'

    vm_name=$1
    image_name=$2
    sec_group=$3
    zone=$4
    host=$5
    user_data_file=$6

    get_vm_id  vm_id 	   $vm_name
    get_net_id mgmt_net_id global_mgmt_net
    
    if [ $vm_id ]
        then
            printf "%s vm already exists so delete it !!!\n" $vm_name
            printf "nova delete %s\n" $vm_name
            nova delete $vm_name
    fi

    cli="nova boot $vm_name
        --flavor 3
        --image $image_name
        --key-name $ADMIN_KEY
        --nic net-id=$mgmt_net_id
        --security-groups $sec_group
        --availability-zone ${zone}:${host}
        --user-data $user_data_file"

    run_cli_as_admin $cli
    
    if ! timeout $vm_create_timeout /bin/bash -c "while ! nova list | grep ${vm_name} | grep ACTIVE; do sleep 5; echo wait.. ; done"; 
    then
        echo "## Instance <$vm_name> failed to go active after $vm_create_timeout seconds"
        exit 1
    else
        echo        
        echo ">> Instance <$vm_name> created"
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
    run_cli_as_admin $cli

    # test we can ping our floating ip within ASSOCIATE_TIMEOUT seconds
    if ! timeout $normal_timeout sh -c "while ! ping -c1 -w1 $FLOATING_IP; do sleep 1; echo wait.. ; done"; then
        echo "#Floating IP<$FLOATING_IP> ping fail !!!!"
        exit 1
    else
        echo        
        echo ">>Floating IP<$FLOATING_IP> ping success !!!!"
    fi
}



allocate_floating_ip()
{
    echo '
    ################################################################################
        floating ip 생성 & 할당 !!!
    ################################################################################'

    vm=$1
    network=$2
    
    get_vm_id vm_id $vm
    echo "nova show $vm_id | grep "$network " | awk '{print \$5}'"
    vm_ip=$(nova show $vm_id | grep "$network " | awk '{print $5}')
    echo "vm_ip <$vm_ip>"
    
    echo "neutron port-list | grep "$vm_ip" | awk '{print \$2}'"
    port_id=$(neutron port-list | grep "$vm_ip" | awk '{print $2}')
    echo "port_id <$port_id>"   
    
    echo "\n###############################"
    echo "[$vm] VM [$network] network: port_id -> [$port_id]"
    
    cli="neutron floatingip-create --port_id $port_id $PUBLIC_NET"    
    run_cli_as_admin $cli

}
