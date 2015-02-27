#!/bin/bash

echo "
################################################################################
#
#   make vm on Private Network Test
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
ADMIN_TENANT_ID=$(keystone tenant-list | awk '/\ admin\ / {print $2}')
ADMIN_TENANT_NAME=admin
PUBLIC_NET=public_net

TEST_TENANT_NAME=admin
TEST_NET=private_network
TEST_SUBNET=private_subnetwork

TEST_KEY=testkey
TEST_KEY_FILE=testkey.pub
TEST_IMAGE=endian_community
TEST_IMAGE=ubuntu-12.04

#TEST_ZONE=east.dj.zo.kt
#TEST_HOST=cnode01
TEST_ZONE=seocho.seoul.zo.kt
TEST_HOST=havana

TEST_VM1=cnode02-1
TEST_VM2=cnode02-2

add_default_security_group()
{
    echo '
    ################################################################################
        1. security_group_add[tcp: 22 open, icmp: enable] !!!
    ################################################################################
    '

    # nova secgroup-delete-rule SEC_GROUP_NAME tcp 22 22 0.0.0.0/0

    printf "nova secgroup-add-rule default tcp  22 22 0.0.0.0/0\n"
    printf "nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0\n"

    # rule이 추가되었음을 확인하고 수행해야 하나 현재는 마땅한 방법이 없슴.
    nova secgroup-add-rule default tcp  22 22 0.0.0.0/0
    nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
}


make_test_keypair()
{
    echo '
    ################################################################################
        2. test key 생성 및 nova keypair 등록 !!!
    ################################################################################
    '

    nova keypair-list

    TEST_KEY_ID=$(nova keypair-list | grep "$TEST_KEY " | awk '{print $2}')
    if [ $TEST_KEY_ID ]
        then
            printf "%s key already exists !!!\n" $TEST_KEY
        else
            printf "%s key creates !!!\n" $TEST_KEY
            rm -f ${TEST_KEY}*

            printf "ssh-keygen -t rsa -f %s -N '' \n" $TEST_KEY
            ssh-keygen -t rsa -f $TEST_KEY -N ""

            printf "nova keypair-add --pub-key %s %s\n" $TEST_KEY_FILE $TEST_KEY
            nova keypair-add --pub-key $TEST_KEY_FILE $TEST_KEY
    fi

}


make_test_vm()
{
    echo '
    ################################################################################
        3. test vm 생성[private, green, orange nic 설정] !!!
    ################################################################################
    '

    TEST_VM=$1
    TEST_IMAGE=$2
    TEST_ZONE=$3
    TEST_HOST=$4

    TEST_TENANT_ID=$(keystone tenant-list | grep "${TEST_TENANT_NAME} " | awk '{print $2}')
    TEST_IMAGE_ID=$(nova image-list | grep "$TEST_IMAGE " | awk '{print $2}')

    echo "TEST_TENANT($TEST_TENANT_NAME) ID: $TEST_TENANT_ID"
    echo "TEST_IMAGE($TEST_IMAGE) ID : $TEST_IMAGE_ID"
    echo "TEST_KEY      : $TEST_KEY"

    TEST_NET_ID=$(neutron net-list | grep "$TEST_NET " | awk '{print $2}')

    printf '\n######################################\n'
    printf '# [%s] vm 생성 => [%s] networks 연결\n' $TEST_VM $TEST_NET
    printf 'TEST_NET         %s -> %s\n' $TEST_NET  $TEST_NET_ID

    get_vm_id _vm_id $TEST_VM
    TEST_VM_ID=$_vm_id
    
    if [ $TEST_VM_ID ]
        then
            printf "%s vm already exists so delete it !!!\n" $TEST_VM
            printf "nova delete %s\n" $TEST_VM
            nova delete $TEST_VM
    fi

    echo "nova boot $TEST_VM
        --flavor 3
        --image $TEST_IMAGE_ID
        --key-name $TEST_KEY
        --nic net-id=$TEST_NET_ID
        --security-groups default
        --availability-zone ${TEST_ZONE}:${TEST_HOST}"

    nova boot $TEST_VM \
        --flavor 3 \
        --image $TEST_IMAGE_ID \
        --key-name $TEST_KEY \
        --nic net-id=$TEST_NET_ID \
        --security-groups default \
        --availability-zone ${TEST_ZONE}:${TEST_HOST}
}


add_floating_ip2testvm()
{
    echo '
    ################################################################################
        4. floating ip 생성 & 할당 !!!
    ################################################################################
    '

    network=$TEST_NET
    subnet=$TEST_SUBNET
    vm=$1
    
    for vm in $TEST_VM1 $TEST_VM2
    do
        get_vm_port_id _port_id $vm $network $subnet $ip_addr
    
        echo "\n###############################"
        echo "[$vm] VM [$network] network: port_id -> [$_port_id]"
        echo "neutron floatingip-create --port_id $_port_id $PUBLIC_NET"
        neutron floatingip-create --port_id $_port_id $PUBLIC_NET
    done    
    
}

make_test_vms() {

    for vm in $TEST_VM1 $TEST_VM2   
    do
        # make_test_vm $vm $TEST_IMAGE seocho.seoul.zo.kt havana
        make_test_vm $vm $TEST_IMAGE seocho.seoul.zo.kt cnode02
        echo $vm
    done

}

make_aging_vms() {

    # for vm in $TEST_VM1 $TEST_VM2 $TEST_VM3 $TEST_VM4 $TEST_VM5 $TEST_VM6 $TEST_VM7 $TEST_VM8 $TEST_VM9 $TEST_VM10
    vms=(cnode02-1 cnode02-2 cnode02-3 cnode02-4 cnode02-5 
         cnode02-6 cnode02-7 cnode02-8 cnode02-9 cnode02-10  
         cnode02-11 cnode02-12 cnode02-13 cnode02-14 cnode02-15
         cnode02-16 cnode02-17 cnode02-18 cnode02-19 cnode02-20)
         
    for vm in ${vms[@]};   
    do
        # make_test_vm $vm $TEST_IMAGE seocho.seoul.zo.kt havana
        # make_test_vm $vm $TEST_IMAGE seocho.seoul.zo.kt cnode02
        echo $vm
    done
    
    for (( i = 0; i < 100; i++))    
    do  
        echo $i
        vm="havana-$i"
        echo $vm
        make_test_vm $vm $TEST_IMAGE seocho.seoul.zo.kt cnode02
    done

}

delete_aging_vms() {    
    
    for (( i = 0; i < 100; i++))    
    do        
        vm="havana-$i"
        echo $vm
        nova delete $vm
    done

}


#add_default_security_group
#make_test_keypair
# make_test_vms
#add_floating_ip2testvm
# delete_aging_vms

make_test_vm havana-make $TEST_IMAGE seocho.seoul.zo.kt havana

