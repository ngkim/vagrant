#!/bin/bash

echo "
################################################################################
#
#   Hybrid Network create
#
################################################################################
"

#
# utm에 할당할 public shared network -> vlan 3001을 사용 
function make_hybrid_red_shared_network()
{
    echo '
    ----------------------------------------------------------------------------
        1. hybrid red(public:shared) network 생성 !!!
    ----------------------------------------------------------------------------
    '
    
    printf 'REGION          : %s\n' $REGION
    printf 'ADMIN_TENANT_ID : %s\n' $ADMIN_TENANT_ID    
    printf 'HYBRID_PHYSNET_NAME : %s\n\n' $HYBRID_PHYSNET_NAME    

    printf 'RED_PUBLIC_NET  : %s\n' $RED_PUBLIC_NET
    printf 'RED_PUBLIC_VLAN : %s\n\n' $RED_PUBLIC_VLAN

    cli="
        neutron net-create $RED_PUBLIC_NET
	        --os-region-name $REGION
	        --tenant-id $ADMIN_TENANT_ID
	        --provider:network_type vlan
	        --provider:physical_network $RED_PUBLIC_PHYSNET_NAME
	        --provider:segmentation_id $RED_PUBLIC_VLAN
	        --shared"

    run_cli_as_admin $cli
        
}

function make_hybrid_red_shared_subnet()
{
    echo '
    ----------------------------------------------------------------------------
        1. hybrid red(public:shared) sub_network 생성 !!!
    ----------------------------------------------------------------------------
    '
    printf '\n############################\n'
    printf '# hybrid red sub-network 생성 !!!'
    printf 'RED_PUBLIC_NET     : %s\n' $RED_PUBLIC_NET
    printf 'RED_PUBLIC_SUBNET  : %s\n' $RED_PUBLIC_SUBNET
    printf 'RED_PUBLIC_SUBNET_CIDR    : %s\n' $RED_PUBLIC_SUBNET_CIDR
    printf 'RED_PUBLIC_IP_RANGE: %s ~ %s\n' ${RED_PUBLIC_IP_POOL_START} ${RED_PUBLIC_IP_POOL_END}
        
    cli="
	    neutron subnet-create $RED_PUBLIC_NET $RED_PUBLIC_SUBNET_CIDR
	        --os-region-name $REGION
	        --tenant-id $ADMIN_TENANT_ID
	        --gateway $RED_PUBLIC_SUBNET_GW
	        --allocation-pool start=${RED_PUBLIC_IP_POOL_START},end=${RED_PUBLIC_IP_POOL_END}
	        --enable_dhcp=False
	        --dns-nameservers list=true $DNS_SERVER1 $DNS_SERVER2
	        --name $RED_PUBLIC_SUBNET"
	run_cli_as_admin $cli
}





