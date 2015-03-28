#!/bin/bash

echo "
################################################################################
#
#   global management network create
#
#   테스트를 위해 여러 테넌트를 만들고 시나리오대로 VM들을 생성한 경우에
#   개별 VM들에 접속할 방법이 마땅치 않으므로 global management network를
#   shared로 만들어 모든 VM들에 연결하게 하고 이를 이용하여 관리를 할 수 있도록 한다.
#
################################################################################
"

function make_mgmt_network()
{
    echo "
    ----------------------------------------------------------------------------
        mgmt_network<<$MGMT_NET>> 생성 !!!
    ----------------------------------------------------------------------------
    "

    # LJG: awk 에러 발생 -> grep 후 awk 처리
    # ADMIN_TENANT_ID=$(keystone tenant-list | awk '/\ ${ADMIN_TENANT_NAME}\ / {print $2}')


    MGMT_NET_ID=$(neutron --os-tenant-name $ADMIN_TENANT_NAME --os-username $ADMIN_USER_NAME --os-password $ADMIN_USER_PASS net-list | grep "$MGMT_NET " | awk '{print $2}')

    if [ $MGMT_NET_ID ]; then
	    printf "%s test network already exists && delete it !!!\n" $MGMT_NET
	    cli="neutron net-delete $MGMT_NET --os-region-name $REGION"        
	    run_cli_as_admin $cli
    fi
    
	cli="neutron net-create $MGMT_NET --os-region-name $REGION --shared"        
	run_cli_as_admin $cli
}

function make_mgmt_subnet()
{
    echo "
    ----------------------------------------------------------------------------
        mgmt_subnet<<$MGMT_SUBNET>> 생성 !!!
    ----------------------------------------------------------------------------
    "

    MGMT_SUBNET_ID=$(neutron --os-tenant-name $ADMIN_TENANT_NAME --os-username $ADMIN_USER_NAME --os-password $ADMIN_USER_PASS subnet-list | grep "$MGMT_SUBNET " | awk '{print $2}')

    if [ $MGMT_SUBNET_ID ]; then
        printf "%s test subnet already exists && delete it!!!\n" $MGMT_SUBNET
        cli="neutron subnet-delete $MGMT_SUBNET --os-region-name $REGION"
	    run_cli_as_admin $cli
    fi
    cli="
        neutron subnet-create $MGMT_NET $MGMT_SUBNET_CIDR 
            --name $MGMT_SUBNET 
            --dns-nameservers list=true 
            $DNS_SERVER1 $DNS_SERVER2"
    run_cli_as_admin $cli
    
}


function make_mgmt_router()
{
    echo "
    ----------------------------------------------------------------------------
        mgmt_router<<$MGMT_ROUTER>> 생성 !!!
    ----------------------------------------------------------------------------
    "

    MGMT_ROUTER_ID=$(neutron --os-tenant-name $ADMIN_TENANT_NAME --os-username $ADMIN_USER_NAME --os-password $ADMIN_USER_PASS router-list | grep "$MGMT_ROUTER " | awk '{print $2}')

    if [ $MGMT_ROUTER_ID ]; then
        printf "%s test router already exists && delete it !!!\n" $MGMT_ROUTER
        cli="neutron router-delete $MGMT_ROUTER"
        run_cli_as_admin $cli
    else
        cli="neutron router-create $MGMT_ROUTER"
        run_cli_as_admin $cli
    fi
}

function add_mgmt_subnet_interface_to_mgmt_router()
{
    echo "
    ----------------------------------------------------------------------------
        add_mgmt_subnet_interface_to_mgmt_router !!!
    ----------------------------------------------------------------------------
    "
    MGMT_SUBNET_ID=$(neutron --os-tenant-name $ADMIN_TENANT_NAME --os-username $ADMIN_USER_NAME --os-password $ADMIN_USER_PASS subnet-list | grep "${MGMT_SUBNET} " | awk '{print $2}')

    cli="neutron router-interface-add $MGMT_ROUTER $MGMT_SUBNET_ID"
    run_cli_as_admin $cli
}

function set_external_gateway_to_mgmt_router()
{
    echo "
    ----------------------------------------------------------------------------
        set_external_gateway_to_mgmt_router !!!
    ----------------------------------------------------------------------------
    "

    MGMT_ROUTER_ID=$(neutron --os-tenant-name $ADMIN_TENANT_NAME --os-username $ADMIN_USER_NAME --os-password $ADMIN_USER_PASS router-list | grep "$MGMT_ROUTER " | awk '{print $2}')
    echo 'MGMT_ROUTER_ID -> ' $MGMT_ROUTER_ID

    PUBLIC_NET_ID=$(neutron --os-tenant-name $ADMIN_TENANT_NAME --os-username $ADMIN_USER_NAME --os-password $ADMIN_USER_PASS net-list | grep "${PUBLIC_NET} " | awk '{print $2}')
    echo 'PUBLIC_NET_ID -> ' $PUBLIC_NET_ID

    cli="neutron router-gateway-set ${MGMT_ROUTER_ID} ${PUBLIC_NET_ID}"
    run_cli_as_admin $cli

}


