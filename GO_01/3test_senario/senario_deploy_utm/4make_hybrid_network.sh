#!/bin/bash

echo "
################################################################################
#
#   hybrid network create
#   - 기본적으로 admin 이 아닌 계정은 네트워크를 생성할 권한이 없으므로
#     admin 계정으로 tenant-id<<$GUEST_TENANT_NAME>>를 이용해서 네트워크를 생성해 준다.
#
################################################################################
"

GUEST_TENANT_ID=$(keystone tenant-list | grep "$GUEST_TENANT_NAME " | awk '{print $2}')

function make_user_hybrid_green_network()
{
    echo "
    ################################################################################
        customer<<$GUEST_USER_NAME>> hybrid_green_network<<$GREEN_NET>> 생성 !!!
    ################################################################################
    "

    GUEST_NET_ID=$(neutron net-list | grep "$GREEN_NET " | awk '{print $2}')
    if [ $GUEST_NET_ID ]; then
	    printf "%s test network already exists & delete it !!!\n" $GREEN_NET
        cli="neutron net-delete $GREEN_NET"        
	    run_cli_as_admin $cli
    fi

    # LJG: 일반 user 계정으로는 guest network를 제외한 hybrid network를 생성할 수 없다.
    #      그래서 admin 계정으로 network를 만들고 --tenant-id를 통해 특정 계정의 소유로 제공한다.
    #       이를 수정하려면 /etc/neutron/policy.json 파일을 변경해야 하나 권장할 사항은 아니다.

    cli="
    neutron net-create $GREEN_NET
        --os-region-name $REGION
        --tenant-id $GUEST_TENANT_ID
        --provider:network_type vlan
        --provider:physical_network $HYBRID_PHYSNET_NAME
        --provider:segmentation_id $GREEN_NET_VLAN
    "

    run_cli_as_admin $cli

}

function make_user_hybrid_green_subnet()
{
    echo "
    ################################################################################
        customer<<$GUEST_USER_NAME>> hybrid_green_subnet<<$GREEN_SUBNET>> 생성 !!!
    ################################################################################
    "

    GUEST_NET_ID=$(neutron subnet-list | grep "$GREEN_SUBNET " | awk '{print $2}')
    if [ $GUEST_NET_ID ]; then
        printf "%s test sub network already exists & delete it !!!\n" $GREEN_SUBNET
        cli="neutron subnet-delete $GREEN_SUBNET"
        run_cli_as_admin $cli
    fi

    # neutron subnet-create --os-tenant-name $GUEST_TENANT_NAME --os-username $GUEST_USER_NAME --os-password $GUEST_USER_PASS \
    cli="
    neutron subnet-create
        $GREEN_NET
        $GREEN_SUBNET_CIDR
        --enable_dhcp=False
        --no-gateway
        --os-region-name $REGION
        --tenant-id $GUEST_TENANT_ID
        --name $GREEN_SUBNET
    "
    run_cli_as_admin $cli

}

function make_user_hybrid_orange_network()
{
    echo "
    ################################################################################
        customer<<$GUEST_USER_NAME>> hybrid_orange_network<<$ORANGE_NET>> 생성 !!!
    ################################################################################
    "

    GUEST_NET_ID=$(neutron net-list | grep "$ORANGE_NET " | awk '{print $2}')
    if [ $GUEST_NET_ID ]; then
        printf "%s test network already exists & delete it !!!\n" $ORANGE_NET
        cli="neutron net-delete $ORANGE_NET"
        run_cli_as_admin $cli
    fi

    # neutron net-create --os-tenant-name $GUEST_TENANT_NAME --os-username $GUEST_USER_NAME --os-password $GUEST_USER_PASS \
    cli="
    neutron net-create $ORANGE_NET
        --os-region-name $REGION
        --tenant-id $GUEST_TENANT_ID
        --provider:network_type vlan
        --provider:physical_network $HYBRID_PHYSNET_NAME
        --provider:segmentation_id $ORANGE_NET_VLAN
    "
    run_cli_as_admin $cli

}

function make_user_hybrid_orange_subnet()
{
    echo "
    ################################################################################
        customer<<$GUEST_USER_NAME>> hybrid_orange_subnet<<$ORANGE_SUBNET>> 생성 !!!
    ################################################################################
    "

    GUEST_NET_ID=$(neutron subnet-list | grep "$ORANGE_SUBNET " | awk '{print $2}')
    if [ $GUEST_NET_ID ]; then
        printf "%s test sub network already exists & delete it !!!\n" $ORANGE_SUBNET
        cli="neutron subnet-delete $ORANGE_SUBNET"
        run_cli_as_admin $cli
    fi

    # neutron subnet-create --os-tenant-name $GUEST_TENANT_NAME --os-username $GUEST_USER_NAME --os-password $GUEST_USER_PASS
    cli="
    neutron subnet-create
        $ORANGE_NET
        $ORANGE_SUBNET_CIDR
        --enable_dhcp=False
        --no-gateway
        --os-region-name $REGION
        --tenant-id $GUEST_TENANT_ID
        --name $ORANGE_SUBNET
    "
    run_cli_as_admin $cli

}