#!/bin/bash

echo "
################################################################################
#
#   Base OpenStack Public Network Create
#
################################################################################
"

make_public_network()
{
    echo '
    ----------------------------------------------------------------------------
        1. public_network 생성 !!!
    ----------------------------------------------------------------------------
    '
    # LJG: router:external을 True로 설정하지 않으면 tenant network의 router에
    #    public network를 gateway르 설정할 때 에러가 발생한다.
    #    예) 400-{u'NeutronError':
    #       'message': 'Bad router request: Network 39c96c80-5721-466d-9e72-20a412d3c654 is not a valid external network',
    #
    # LJG: public은 flat network 이므로 vlan 설정 안되있으므로 아래설정 필요없슴
    #   --provider:segmentation_id $PUBLIC_VLAN

    cli="neutron net-create $PUBLIC_NET
        --os-region-name $REGION
        --tenant-id $ADMIN_TENANT_ID
        --provider:network_type vlan
        --provider:physical_network $PUBLIC_PHYSNET_NAME
        --provider:segmentation_id $PUBLIC_VLAN
        --router:external True
        --dns-nameservers list=true $DNS_SERVER1 $DNS_SERVER2
        --shared"
        
    cli="neutron net-create $PUBLIC_NET 
        --router:external True
        --shared"
    
    run_cli_as_admin $cli
    
}

make_public_sub_network()
{
    echo '
    ----------------------------------------------------------------------------
        2. public sub_network 생성 !!!
    ----------------------------------------------------------------------------
    '
    
    # floating-ip 용도이므로 dhcp를 사용하지 않는다
    cli="neutron subnet-create $PUBLIC_NET $PUBLIC_SUBNET_CIDR
        --os-region-name $REGION
        --tenant-id $ADMIN_TENANT_ID
        --gateway $PUBLIC_SUBNET_GW
        --allocation-pool start=${PUBLIC_IP_POOL_START},end=${PUBLIC_IP_POOL_END}
        --enable_dhcp=False
        --dns-nameservers list=true $DNS_SERVER1 $DNS_SERVER2
        --name $PUBLIC_SUBNET"
    
    run_cli_as_admin $cli 
}



