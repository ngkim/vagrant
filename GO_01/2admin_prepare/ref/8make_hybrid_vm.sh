#!/bin/bash

echo "
################################################################################
#
#   make vm on Hybrid Network Test
#
################################################################################
"

source ./0common.sh

# LJG: cnode 주요 디렉토리: 아래 디렉토리들의 역할이 무엇인지 분석하자!!!
#   /var/lib/nova/instances
#   /etc/libvirt/qemu
#   /var/run/libvirt/qemu

################################################################################
#
#   make test vm with attaching 3 networks(red, green, orange)
#
################################################################################

export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=ohhberry3333
export OS_AUTH_URL=http://10.0.0.101:5000/v2.0/
export OS_NO_CACHE=1

REGION=regionOne
ADMIN_TENANT_ID=$(keystone tenant-list | awk '/\ admin\ / {print $2}')
ADMIN_TENANT_NAME=admin
PUBLIC_NET=public_net
PUBLIC_SUBNET=public_subnet

TEST_TENANT_NAME=admin
TEST_USER_NAME=admin
TEST_USER_PASS=ohhberry3333
TEST_NET=test_net
TEST_SUBNET=test_subnet

TEST_KEY=testkey
TEST_KEY_FILE=testkey.pub
TEST_IMAGE=endian_community
TEST_IMAGE=ubuntu-12.04
TEST_VM1=hybrid_vm1_ubuntu-12.04
TEST_VM2=hybrid_vm2_ubuntu-12.04

# red shared network info
RED_PUBLIC_NET=red_shared_public_net

# green network info
GREEN_VLAN1_NET=green_vlan1_net
GREEN_VLAN2_NET=green_vlan2_net

# orange network info
ORANGE_VLAN1_NET=orange_vlan1_net
ORANGE_VLAN2_NET=orange_vlan2_net


make_test_vm()
{
    echo '
    ################################################################################
        3. test vm 생성[red, green, orange nic 설정] !!!
    ################################################################################
    '

    TEST_VM=$1
    TEST_IMAGE=$2
    TEST_ZONE=$3
    TEST_HOST=$4
    red_net=$5
    green_net=$6
    orange_net=$7

    TEST_TENANT_ID=$(keystone tenant-list | grep "${TEST_TENANT_NAME} " | awk '{print $2}')
    TEST_IMAGE_ID=$(nova image-list | grep "$TEST_IMAGE " | awk '{print $2}')

    echo 'TEST_TENANT_ID: ' $TEST_TENANT_ID
    echo 'TEST_IMAGE_ID : ' $TEST_IMAGE_ID
    echo 'TEST_KEY      : ' $TEST_KEY
    
    echo "TEST_VM       <$TEST_VM>"
    echo "TEST_IMAGE    <$TEST_IMAGE>"
    echo "TEST_ZONE     <$TEST_ZONE>"
    echo "TEST_HOST     <$TEST_HOST>"
    echo "red_net       <$red_net>"
    echo "green_net     <$green_net>"
    echo "orange_net    <$orange_net>"                    

    RED_PUBLIC_NET_ID=$(neutron net-list | grep "$red_net " | awk '{print $2}')
    GREEN_VLAN_NET_ID=$(neutron net-list | grep "$green_net " | awk '{print $2}')
    ORANGE_VLAN_NET_ID=$(neutron net-list | grep "$orange_net " | awk '{print $2}')

    echo '# --------------------------------------------------------------------'
    printf '# [%s] vm 생성 => [%s, %s, %s] networks 연결\n' $TEST_VM $red_net $green_net $orange_net
    printf '%20s -> %s\n' $red_net   $RED_PUBLIC_NET_ID
    printf '%20s -> %s\n' $green_net  $GREEN_VLAN_NET_ID
    printf '%20s -> %s\n' $orange_net $ORANGE_VLAN_NET_ID
    echo '# --------------------------------------------------------------------'

    TEST_VM_ID=$(nova list | grep "$TEST_VM " | awk '{print $2}')
    if [ $TEST_VM_ID ]
        then
            printf "%s vm already exists so delete it !!!\n" $TEST_VM
            printf "nova delete %s\n" $TEST_VM
            nova delete $TEST_VM
    fi

    echo "nova boot $TEST_VM
        --flavor 3
        --image $TEST_IMAGE
        --key-name $TEST_KEY
        --nic net-id=$RED_PUBLIC_NET_ID
        --nic net-id=$GREEN_VLAN_NET_ID
        --nic net-id=$ORANGE_VLAN_NET_ID
        --availability-zone ${TEST_ZONE}:${TEST_HOST}
        --security-groups default
    "

    nova boot $TEST_VM \
        --flavor 3 \
        --image $TEST_IMAGE \
        --key-name $TEST_KEY \
        --nic net-id=$RED_PUBLIC_NET_ID  \
        --nic net-id=$GREEN_VLAN_NET_ID \
        --nic net-id=$ORANGE_VLAN_NET_ID \
        --availability-zone ${TEST_ZONE}:${TEST_HOST} \
        --security-groups default


}

make_test_vms() {

    #for vm in $TEST_VM1 $TEST_VM2
    #do
    #    make_test_vm $vm $TEST_IMAGE seocho.seoul.zo.kt havana
    #done
    
    echo "make_test_vm $TEST_VM1 $TEST_IMAGE seocho.seoul.zo.kt havana $RED_PUBLIC_NET $GREEN_VLAN1_NET $ORANGE_VLAN1_NET"
    make_test_vm $TEST_VM1 $TEST_IMAGE seocho.seoul.zo.kt havana $RED_PUBLIC_NET $GREEN_VLAN1_NET $ORANGE_VLAN1_NET

    echo "make_test_vm $TEST_VM2 $TEST_IMAGE seocho.seoul.zo.kt havana $RED_PUBLIC_NET $GREEN_VLAN2_NET $ORANGE_VLAN2_NET"
    make_test_vm $TEST_VM2 $TEST_IMAGE seocho.seoul.zo.kt havana $RED_PUBLIC_NET $GREEN_VLAN2_NET $ORANGE_VLAN2_NET
}

make_test_vms


