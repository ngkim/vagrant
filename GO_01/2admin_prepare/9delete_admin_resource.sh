#!/bin/bash

customer=$1
if [[ -z "$customer" ]]; then
    echo "에려  :: customer 이름을 입력하세요!!!"
    echo "사용법:: 6delete_user_resource.sh customer_name"
    exit
fi

source ./common_env
source ./common_lib

echo "
################################################################################
#
#   <<$customer>> 가 사용중인 리소스를 모두 삭제하려고 합니다.
#   매우 위험한 명령이오니 반드시 확인하세요 !!!
#
################################################################################
"
# LJG: 사용자 환경으로 cli 환경을 설정해야 함. 매우 중요!!!
set_openstack_cli_admin_env

echo "#########################################################################"
echo "CLI를 실행하기 위한 사용자 환경"
echo "#########################################################################"
env | grep OS_
echo "#########################################################################"

ask_continue_stop

echo "#########################################################################"
echo "진짜 잘 확인했소??? 특히 admin 환경이면 대형사고 임!!!"
echo "#########################################################################"

ask_yes_no _answer "진짜 삭제하실라우??" 

if [ "$_answer" == "y" ]; then
    echo "삭제한다네!!!!"
else
    echo "그럼 조심해야지!!!!"
    exit
fi

# LJG: 매우 중요 -> 실수로 admin 권한으로 삭제하면 모두 지워진다.
#      그리고 리소스 사이의 상관관계를 생각해서 삭제하는 것이 중요

function show_user_using_resource() {

    echo "
    ################################################################################
    #
    #   <<$customer>> using resources status
    #
    ################################################################################
    "

    printf "\n<<$customer>> using floatingip list\n"
    neutron floatingip-list
    
    printf "\n<<$customer>> using port list\n"
    neutron port-list
    
    printf "\n<<$customer>> using router list\n"
    neutron router-list
    
    printf "\n<<$customer>> using subnet list\n"
    neutron subnet-list
    
    printf "\n<<$customer>> using net list\n"
    neutron net-list
    
    printf "\n<<$customer>> using vm list\n"
    nova list

}




function show_current_cloud_status()
{
    echo '######################################################################'
    echo ''
    echo '## tenant list !!!'
    keystone tenant-list
    
    echo ''
    echo '## user list !!!'
    keystone user-list
    
    echo ''
    echo '## network list !!!'
    neutron net-list

    echo ''
    echo '## subnet list !!!'
    neutron subnet-list

    echo ''
    echo '## port list !!!'
    neutron port-list
    
    echo ''
    echo '## router list !!!'
    neutron router-list
    
    echo '###############################'
    echo ''
}


purge_floatingip()
{
    echo '######################################################################'
    echo '## purge_floatingip'
    for fip in `neutron floatingip-list -c id | egrep -v '\-\-|id' | awk '{print $2}'`
    do
        echo "neutron floatingip-delete ${fip}"
        neutron floatingip-delete ${fip}
        
    done
    echo '###############################'
    echo ''
}


purge_port()
{
    echo '######################################################################'
    echo '## purge_port'
    for port in `neutron port-list -c id | egrep -v '\-\-|id' | awk '{print $2}'`
    do
        echo "neutron port-delete ${port}"
        neutron port-delete ${port}
    done
    echo '###############################'
    echo ''
}

purge_router()
{
    echo '######################################################################'
    echo '## purge_router'
    for router in `neutron router-list -c id | egrep -v '\-\-|id' | awk '{print $2}'`
    do
        for subnet in `neutron router-port-list ${router} -c fixed_ips -f csv | egrep -o '[0-9a-z\-]{36}'`
        do
            echo "neutron router-interface-delete ${router} ${subnet}"
            neutron router-interface-delete ${router} ${subnet}
        done
        
        echo "neutron router-gateway-clear ${router}"
        neutron router-gateway-clear ${router}
        echo "neutron router-delete ${router}"
        neutron router-delete ${router}
        
    done
    echo '###############################'
    echo ''
}

purge_subnet()
{
    echo '######################################################################'
    echo '## purge_subnet'
    for subnet in `neutron subnet-list -c id | egrep -v '\-\-|id' | awk '{print $2}'`
    do
        echo "neutron subnet-delete ${subnet}"
        neutron subnet-delete ${subnet}
    done
    echo '###############################'
    echo 
}


purge_net()
{
    echo '######################################################################'
    echo '## purge_net'
    for net in `neutron net-list -c id | egrep -v '\-\-|id' | awk '{print $2}'`
    do
        echo '  -> ' ${net}
        echo "neutron net-delete ${net}"
        neutron net-delete ${net}
    done
    
    echo '###############################'
    echo ''
}

purge_vm()
{
    echo '######################################################################'
    echo '## purge_vm'
    for vm in `nova list --all-tenants| egrep -v '\-\-|ID' | awk '{print $2}'`
    do
        echo '  -> ' ${vm}
        echo "nova delete ${vm}"
        nova delete ${vm}
    done
    
    echo '###############################'
    echo ''
}


purge_user_resource()
{
    # LJG: 삭제순서가 중요함: router 관련부분 부터 정리해야 함.
    #      현재 테스트 결과 router 관련 interface, subnet, port가 정리되면
    #      net-delete로 하부 자료(subnet)가 정리됨 
    purge_floatingip
    purge_router
    purge_port
    purge_subnet    
    purge_net
    purge_vm

}

show_user_using_resource
purge_user_resource
