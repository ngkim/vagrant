#!/bin/bash

echo "
################################################################################
#
#   Hybrid Network Test
#
################################################################################
"

REGION=regionOne

# LJG: public network(floating ip 할당용)
#      현재 West 에서 90번까지는 사용하는 듯함.
ADMIN_TENANT_NAME=admin
get_tenant_id _tenant_id ${ADMIN_TENANT_NAME}
ADMIN_TENANT_ID=$_tenant_id

HYBRID_PHYSNET_NAME=physnet_hybrid

# red shared network info
RED_PUBLIC_NET=red_shared_public_net
RED_PUBLIC_SUBNET=red_shared_public_subnet
RED_PUBLIC_SUBNET_CIDR=221.145.180.64/26
RED_PUBLIC_SUBNET_GW=221.145.180.65
RED_PUBLIC_IP_POOL_START=221.145.180.96
RED_PUBLIC_IP_POOL_END=221.145.180.99
RED_PUBLIC_PHYSNET_NAME=physnet_hybrid
RED_PUBLIC_VLAN=2000

get_tenant_id _tenant_id ${TEST_TENANT_NAME}
TEST_TENANT_ID=$_tenant_id

# green network info
GREEN_VLAN1_NET=green_vlan1_net
GREEN_VLAN1_SUBNET=green_vlan1_subnet
GREEN_VLAN1=110
GREEN_IP_POOL_START=192.168.0.1
GREEN_IP_POOL_END=192.168.0.230
GREEN_VLAN_CIDR=192.168.0.0/24

# orange network info
ORANGE_VLAN1_NET=orange_vlan1_net
ORANGE_VLAN1_SUBNET=orange_vlan1_subnet
ORANGE_VLAN1=100
ORANGE_IP_POOL_START=192.168.0.254
ORANGE_IP_POOL_END=192.168.0.255
ORANGE_VLAN_CIDR=192.168.0.254/27

#
# utm에 할당할 public shared network -> vlan 3001을 사용 
make_hybrid_red_shared_network()
{
    echo '
    ################################################################################
        1. hybrid red(public:shared) network 생성 !!!
    ################################################################################
    '
    
    printf 'REGION          : %s\n' $REGION
    printf 'ADMIN_TENANT_ID : %s\n' $ADMIN_TENANT_ID    
    printf 'HYBRID_PHYSNET_NAME : %s\n\n' $HYBRID_PHYSNET_NAME    

    printf 'RED_PUBLIC_NET  : %s\n' $RED_PUBLIC_NET
    printf 'RED_PUBLIC_VLAN : %s\n\n' $RED_PUBLIC_VLAN

    echo "neutron net-create $RED_PUBLIC_NET
        --os-region-name $REGION
        --tenant-id $ADMIN_TENANT_ID
        --provider:network_type vlan
        --provider:physical_network $RED_PUBLIC_PHYSNET_NAME
        --provider:segmentation_id $RED_PUBLIC_VLAN
        --shared"

    
    neutron net-create $RED_PUBLIC_NET \
        --os-region-name $REGION \
        --tenant-id $ADMIN_TENANT_ID \
        --provider:network_type vlan \
        --provider:physical_network $RED_PUBLIC_PHYSNET_NAME \
        --provider:segmentation_id $RED_PUBLIC_VLAN \
        --shared
        
}

make_hybrid_green_network()
{
    echo '
    ################################################################################
        2. hybrid_green_network 생성 !!!
    ################################################################################
    '
    
    printf 'REGION          : %s\n' $REGION
    printf 'TEST_TENANT_ID : %s\n' $TEST_TENANT_ID    
    printf 'HYBRID_PHYSNET_NAME : %s\n\n' $HYBRID_PHYSNET_NAME
    
    printf '\n############################\n'
    printf '# green network 1 생성 !!!\n'
    printf 'GREEN_VLAN1_NET : %s\n' $GREEN_VLAN1_NET
    printf 'GREEN_VLAN1     : %s\n\n' $GREEN_VLAN1
    
    echo "neutron net-create $GREEN_VLAN1_NET
        --os-region-name $REGION
        --tenant-id $TEST_TENANT_ID
        --provider:network_type vlan
        --provider:physical_network $HYBRID_PHYSNET_NAME
        --provider:segmentation_id $GREEN_VLAN1"
    
    neutron net-create $GREEN_VLAN1_NET \
        --os-region-name $REGION \
        --tenant-id $TEST_TENANT_ID \
        --provider:network_type vlan \
        --provider:physical_network $HYBRID_PHYSNET_NAME \
        --provider:segmentation_id $GREEN_VLAN1

}

make_hybrid_orange_network()
{
    echo '
    ################################################################################
        3. hybrid_orange_network 생성 !!!
    ################################################################################
    '
    
    printf 'REGION          : %s\n' $REGION
    printf 'TEST_TENANT_ID : %s\n' $TEST_TENANT_ID    
    printf 'HYBRID_PHYSNET_NAME : %s\n\n' $HYBRID_PHYSNET_NAME
    
    printf '\n############################\n'
    printf '# orange network 1 생성 !!!\n'
    printf 'ORANGE_VLAN1_NET : %s\n' $ORANGE_VLAN1_NET
    printf 'ORANGE_VLAN1     : %s\n\n' $ORANGE_VLAN1
    
    echo "neutron net-create $ORANGE_VLAN1_NET
        --os-region-name $REGION
        --tenant-id $TEST_TENANT_ID
        --provider:network_type vlan
        --provider:physical_network $HYBRID_PHYSNET_NAME
        --provider:segmentation_id $ORANGE_VLAN1"
            
    neutron net-create $ORANGE_VLAN1_NET \
        --os-region-name $REGION \
        --tenant-id $TEST_TENANT_ID \
        --provider:network_type vlan \
        --provider:physical_network $HYBRID_PHYSNET_NAME \
        --provider:segmentation_id $ORANGE_VLAN1
    
        
}

make_hybrid_red_shared_subnet()
{
    echo '
    ################################################################################
        1. hybrid red(public:shared) sub_network 생성 !!!
    ################################################################################
    '
    printf '\n############################\n'
    printf '# hybrid red sub-network 생성 !!!'
    printf 'RED_PUBLIC_NET     : %s\n' $RED_PUBLIC_NET
    printf 'RED_PUBLIC_SUBNET  : %s\n' $RED_PUBLIC_SUBNET
    printf 'RED_PUBLIC_SUBNET_CIDR    : %s\n' $RED_PUBLIC_SUBNET_CIDR
    printf 'RED_PUBLIC_IP_RANGE: %s ~ %s\n' ${RED_PUBLIC_IP_POOL_START} ${RED_PUBLIC_IP_POOL_END}
        
    echo "neutron subnet-create $RED_PUBLIC_NET $RED_PUBLIC_SUBNET_CIDR
        --os-region-name $REGION
        --tenant-id $ADMIN_TENANT_ID
        --allocation-pool start=${RED_PUBLIC_IP_POOL_START},end=${RED_PUBLIC_IP_POOL_END}
        --enable_dhcp=False
        --name $RED_PUBLIC_SUBNET"
                    
    neutron subnet-create $RED_PUBLIC_NET $RED_PUBLIC_SUBNET_CIDR \
        --os-region-name $REGION \
        --tenant-id $ADMIN_TENANT_ID \
        --allocation-pool start=${RED_PUBLIC_IP_POOL_START},end=${RED_PUBLIC_IP_POOL_END} \
        --enable_dhcp=False \
        --name $RED_PUBLIC_SUBNET
}


make_hybrid_green_subnet()
{
    echo '
    ################################################################################
        2. hybrid sub_network 생성 !!!
    ################################################################################
    '
    
    printf 'REGION          : %s\n' $REGION
    printf 'TEST_TENANT_ID : %s\n' $TEST_TENANT_ID    
    
    printf '\n############################\n'
    printf '# green sub-network 1 생성 !!!'
    printf 'GREEN_VLAN1_NET     : %s\n' $GREEN_VLAN1_NET
    printf 'GREEN_VLAN1_SUBNET  : %s\n' $GREEN_VLAN1_SUBNET
    printf 'GREEN_VLAN1_CIDR    : %s\n' $GREEN_VLAN1_CIDR
    
    echo "neutron subnet-create $GREEN_VLAN1_NET $GREEN_VLAN1_CIDR
        --enable_dhcp=False
        --no-gateway \
        --os-region-name $REGION
        --tenant-id $TEST_TENANT_ID
        --allocation-pool start=${GREEN_IP_POOL_START},end=${GREEN_IP_POOL_END}
        --name $GREEN_VLAN1_SUBNET"
        
    neutron subnet-create $GREEN_VLAN1_NET $GREEN_VLAN1_CIDR \
        --enable_dhcp=False \
        --no-gateway \
        --os-region-name $REGION \
        --tenant-id $TEST_TENANT_ID \
        --allocation-pool start=${GREEN_IP_POOL_START},end=${GREEN_IP_POOL_END}
        --name $GREEN_VLAN1_SUBNET

}

make_hybrid_orange_subnet()
{
    echo '
    ################################################################################
        2. hybrid sub_network 생성 !!!
    ################################################################################
    '
    
    printf 'REGION          : %s\n' $REGION
    printf 'TEST_TENANT_ID : %s\n' $TEST_TENANT_ID    

    printf '\n############################\n'
    printf '# orange sub-network 1 생성 !!!'
    printf 'ORANGE_VLAN1_NET     : %s\n' $ORANGE_VLAN1_NET
    printf 'ORANGE_VLAN1_SUBNET  : %s\n' $ORANGE_VLAN1_SUBNET
    printf 'ORANGE_VLAN1_CIDR    : %s\n' $ORANGE_VLAN1_CIDR
    
    echo "neutron subnet-create $ORANGE_VLAN1_NET $ORANGE_VLAN1_CIDR
        --enable_dhcp=False
        --no-gateway 
        --os-region-name $REGION
        --tenant-id $TEST_TENANT_ID
        --name $ORANGE_VLAN1_SUBNET"
        
    neutron subnet-create $ORANGE_VLAN1_NET $ORANGE_VLAN1_CIDR \
        --enable_dhcp=False \
        --no-gateway \
        --os-region-name $REGION \
        --tenant-id $TEST_TENANT_ID \
        --allocation-pool start=${ORANGE_IP_POOL_START},end=${ORANGE_IP_POOL_END} \
        --name $ORANGE_VLAN1_SUBNET

}

make_hybrid_red_shared_network
make_hybrid_red_shared_subnet
make_hybrid_green_network
make_hybrid_orange_network
make_hybrid_green_subnet
make_hybrid_orange_subnet
