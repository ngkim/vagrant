#!/bin/bash

echo "
################################################################################
#
#   Base OpenStack Private Network Test
#
################################################################################
"
source ./0common.sh

export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=ohhberry3333
export OS_AUTH_URL=http://10.0.0.101:5000/v2.0/
export OS_NO_CACHE=1

REGION=regionOne
PUBLIC_NET=public_net
PRIVATE_PHYSNET_NAME=physnet_guest

TEST_TENANT_NAME=admin
TEST_USER_NAME=admin
TEST_USER_PASS=ohhberry3333
TEST_ROLE_NAME=my_role

TEST_NET=private_network
TEST_SUBNET=private_subnetwork
TEST_SUBNET_CIDR=10.10.10.0/24
TEST_ROUTER=private_router

make_test_customer()
{
    echo '
    ################################################################################
        1. customer tenant(test)/user(test) 생성 및 role(member) 추가 !!!
    ################################################################################
    '
    
    TEST_TENANT_ID=$(keystone tenant-list | grep "$TEST_TENANT_NAME " | awk '{print $2}')
    if [ $TEST_TENANT_ID ]
        then
            echo "$TEST_TENANT_NAME tenant already exists !!!" 
        else
            echo "keystone tenant-create --name $TEST_TENANT_NAME"
            keystone tenant-create --name $TEST_TENANT_NAME
    fi
    
    TEST_USER_ID=$(keystone user-list --tenant $TEST_TENANT_NAME | grep "$TEST_USER_NAME " | awk '{print $2}')
    if [ $TEST_USER_ID ]
        then
            echo "$TEST_USER_NAME user already exists !!!" 
        else
            echo "keystone user-create --name $TEST_USER_NAME --tenant $TEST_TENANT_NAME --pass $TEST_USER_PASS --enabled true"
            keystone user-create --name $TEST_USER_NAME --tenant $TEST_TENANT_NAME --pass $TEST_USER_PASS --enabled true
    fi
    
    TEST_ROLE_ID=$(keystone user-role-list --tenant $TEST_TENANT_NAME | grep "$TEST_ROLE_NAME " | awk '{print $2}')
    if [ $TEST_ROLE_ID ]
        then            
            echo "$TEST_ROLE_NAME user-role already exists !!!"
        else
            echo "keystone user-role-add --user $TEST_USER_NAME --role $TEST_ROLE_NAME --tenant $TEST_TENANT_NAME"
            keystone user-role-add --user $TEST_USER_NAME --role $TEST_ROLE_NAME --tenant $TEST_TENANT_NAME
    fi
    
}

make_test_network()
{
    echo '
    ################################################################################
        2. customer(test) test_network(test_net) 생성 !!!
    ################################################################################
    '
    # LJG: awk 에러 발생 -> grep 후 awk 처리
    # TEST_TENANT_ID=$(keystone tenant-list | awk '/\ ${TEST_TENANT_NAME}\ / {print $2}')
    TEST_TENANT_ID=$(keystone tenant-list | grep "${TEST_TENANT_NAME} " | awk '{print $2}')    
    TEST_NET_ID=$(neutron net-list --tenant $TEST_TENANT_NAME | grep "$TEST_NET " | awk '{print $2}')

    if [ $TEST_NET_ID ]
        then
            printf "%s test network already exists !!!\n" $TEST_NET
        else
            printf "neutron net-create %s
                --os-region-name %s
                --tenant-id %s\n" $TEST_NET $REGION $TEST_TENANT_ID 
            
            neutron net-create $TEST_NET \
                --os-region-name $REGION \
                --tenant-id $TEST_TENANT_ID 
    fi

}

make_test_subnet()
{
    echo '
    ################################################################################
        3. customer(test) test_subnet(test_subnet) 생성 !!!
    ################################################################################
    '
    
    TEST_TENANT_ID=$(keystone tenant-list | grep "${TEST_TENANT_NAME} " | awk '{print $2}')    
    TEST_SUBNET_ID=$(neutron subnet-list --tenant $TEST_TENANT_NAME | grep "$TEST_SUBNET " | awk '{print $2}')

    if [ $TEST_SUBNET_ID ]
        then
            printf "%s test subnet already exists !!!\n" $TEST_SUBNET
        else
            printf "neutron subnet-create %s %s
                --tenant-id %s --name %s\n" $TEST_NET $TEST_SUBNET_CIDR $TEST_TENANT_ID $TEST_SUBNET
        
            neutron subnet-create $TEST_NET $TEST_SUBNET_CIDR \
                --tenant-id ${TEST_TENANT_ID} --name $TEST_SUBNET
    fi
}

make_test_router()
{
    echo '
    ################################################################################
        4. customer test router() 생성 !!!
    ################################################################################
    '
    TEST_TENANT_ID=$(keystone tenant-list | grep "${TEST_TENANT_NAME} " | awk '{print $2}')
    TEST_ROUTER_ID=$(neutron router-list --tenant $TEST_TENANT_NAME | grep "$TEST_ROUTER " | awk '{print $2}')

    if [ $TEST_ROUTER_ID ]
        then
            printf "%s test router already exists !!!\n" $TEST_ROUTER
        else
            printf "neutron router-create %s --tenant-id %s\n" $TEST_ROUTER $TEST_TENANT_ID        
            neutron router-create $TEST_ROUTER --tenant-id ${TEST_TENANT_ID}
    fi
}

add_test_subnet2router()
{
    echo '
    ################################################################################
        5. customer router에 subnet 연결 !!!
    ################################################################################
    '
    TEST_SUBNET_ID=$(neutron subnet-list | grep "${TEST_SUBNET} " | awk '{print $2}')
    echo 'TEST_SUBNET_ID -> ' $TEST_SUBNET_ID
    printf "neutron router-interface-add %s %s" $TEST_ROUTER $TEST_SUBNET_ID
    neutron router-interface-add $TEST_ROUTER $TEST_SUBNET_ID

}

add_public_network2router()
{
    echo '
    ################################################################################
        6. customer router에 public_network 연결 !!!
    ################################################################################
    '
    TEST_ROUTER_ID=$(neutron router-list | grep "$TEST_ROUTER " | awk '{print $2}')
    echo 'TEST_ROUTER_ID -> ' $TEST_ROUTER_ID
    
    PUBLIC_NET_ID=$(neutron net-list | grep "${PUBLIC_NET} " | awk '{print $2}')
    echo 'PUBLIC_NET_ID -> ' $PUBLIC_NET_ID
 
    printf "neutron router-gateway-set %s %s" $TEST_ROUTER_ID $PUBLIC_NET_ID
    neutron router-gateway-set ${TEST_ROUTER_ID} ${PUBLIC_NET_ID}

}

show_current_cloud_test_status()
{
    echo '######################################################################'
    echo ''
    echo '## test tenant list !!!'
    
    #for tenant in `keystone tenant-list | grep test | awk '{print $2}'`
    #do
    #    echo '  -> ' ${tenant}
    #done
    keystone tenant-list | grep ${TEST_TENANT_NAME} 
    
    echo ''
    echo '## test user list !!!'
    keystone user-list  | grep ${TEST_USER_NAME}
    
    echo ''
    echo '## test network list !!!'
    neutron net-list  | grep ${TEST_NET}

    echo ''
    echo '## test subnet list !!!'
    neutron subnet-list  | grep ${TEST_SUBNET}

    echo ''
    echo '## port list !!!'
    neutron port-list

    echo ''
    echo '## test router list !!!'
    neutron router-list  | grep ${TEST_ROUTER}

    echo ''
    echo '## test router port list !!!'
    TEST_ROUTER_ID=$(neutron router-list | grep "${TEST_ROUTER} " | awk '{print $2}')
    # echo 'TEST_ROUTER_ID: <'$TEST_ROUTER_ID'>'
    if [ $TEST_ROUTER_ID ]
        then
            neutron router-port-list $TEST_ROUTER_ID
    fi
    echo '###############################'
    echo ''
    
}

run()
{
    make_test_customer
    make_test_network
    make_test_subnet
    make_test_router
    add_test_subnet2router
    add_public_network2router
}

run

