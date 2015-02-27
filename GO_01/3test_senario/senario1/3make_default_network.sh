#!/bin/bash

echo "
################################################################################
#
#   default network create
#
################################################################################
"


function make_user_guest_network()
{
    echo "
    ################################################################################
        customer<<$GUEST_USER_NAME>> guest_network<<$GUEST_NET>> 생성 !!!
    ################################################################################
    "

    # LJG: awk 에러 발생 -> grep 후 awk 처리
    # GUEST_TENANT_ID=$(keystone tenant-list | awk '/\ ${GUEST_TENANT_NAME}\ / {print $2}')


    GUEST_NET_ID=$(neutron --os-tenant-name $GUEST_TENANT_NAME --os-username $GUEST_USER_NAME --os-password $GUEST_USER_PASS net-list | grep "$GUEST_NET " | awk '{print $2}')

    if [ $GUEST_NET_ID ]; then
	    printf "%s test network already exists && delete it !!!\n" $GUEST_NET
	    cli="neutron net-delete $GUEST_NET --os-region-name $REGION"        
	    run_cli_as_user $cli
    fi
    
	cli="neutron net-create $GUEST_NET --os-region-name $REGION"        
	run_cli_as_user $cli
}

function make_user_guest_subnet()
{
    echo "
    ################################################################################
        customer<<$GUEST_USER_NAME>> guest_subnet<<$GUEST_SUBNET>> 생성 !!!
    ################################################################################
    "

    GUEST_SUBNET_ID=$(neutron --os-tenant-name $GUEST_TENANT_NAME --os-username $GUEST_USER_NAME --os-password $GUEST_USER_PASS subnet-list | grep "$GUEST_SUBNET " | awk '{print $2}')

    if [ $GUEST_SUBNET_ID ]; then
        printf "%s test subnet already exists && delete it!!!\n" $GUEST_SUBNET
        cli="neutron subnet-delete $GUEST_SUBNET --os-region-name $REGION"
	    run_cli_as_user $cli
    fi
    cli="neutron subnet-create $GUEST_NET $GUEST_SUBNET_CIDR --name $GUEST_SUBNET --dns-nameservers list=true 8.8.8.8  8.8.4.4"
    run_cli_as_user $cli
    
}


function make_user_router()
{
    echo "
    ################################################################################
        customer<<$GUEST_USER_NAME>> guest_router<<$GUEST_ROUTER>> 생성 !!!
    ################################################################################
    "

    GUEST_ROUTER_ID=$(neutron --os-tenant-name $GUEST_TENANT_NAME --os-username $GUEST_USER_NAME --os-password $GUEST_USER_PASS router-list | grep "$GUEST_ROUTER " | awk '{print $2}')

    if [ $GUEST_ROUTER_ID ]; then
        printf "%s test router already exists && delete it !!!\n" $GUEST_ROUTER
        cli="neutron router-delete $GUEST_ROUTER"
        run_cli_as_user $cli
    else
        cli="neutron router-create $GUEST_ROUTER"
        run_cli_as_user $cli
    fi
}

function add_guest_subnet_interface_to_user_router()
{
    echo "
    ################################################################################
        customer<<$GUEST_USER_NAME>> add_guest_subnet_interface_to_user_router !!!
    ################################################################################
    "
    GUEST_SUBNET_ID=$(neutron --os-tenant-name $GUEST_TENANT_NAME --os-username $GUEST_USER_NAME --os-password $GUEST_USER_PASS subnet-list | grep "${GUEST_SUBNET} " | awk '{print $2}')

    cli="neutron router-interface-add $GUEST_ROUTER $GUEST_SUBNET_ID"
    run_cli_as_user $cli
}

function set_external_gateway_to_user_router()
{
    echo "
    ################################################################################
        customer<<$GUEST_USER_NAME>> set_external_gateway_to_user_router !!!
    ################################################################################
    "

    GUEST_ROUTER_ID=$(neutron --os-tenant-name $GUEST_TENANT_NAME --os-username $GUEST_USER_NAME --os-password $GUEST_USER_PASS router-list | grep "$GUEST_ROUTER " | awk '{print $2}')
    echo 'GUEST_ROUTER_ID -> ' $GUEST_ROUTER_ID

    PUBLIC_NET_ID=$(neutron --os-tenant-name $GUEST_TENANT_NAME --os-username $GUEST_USER_NAME --os-password $GUEST_USER_PASS net-list | grep "${PUBLIC_NET} " | awk '{print $2}')
    echo 'PUBLIC_NET_ID -> ' $PUBLIC_NET_ID

    cli="neutron router-gateway-set ${GUEST_ROUTER_ID} ${PUBLIC_NET_ID}"
    run_cli_as_user $cli

}