#!/bin/bash

#  allinone_topology_variable_setting.sh

echo "

# ------------------------------------------------------------------------------
#  allinone_topology_variable_setting.sh
# ------------------------------------------------------------------------------

오픈스택을 구성하는 아키텍처에 따라 인프라를 구성하는데 필요한 환경을 설정한다.
 
All-in-one :: 하나의 서버에 모든 오픈스택 구성요소를 설치

- server dns naming : HOSTNAME.POD.LOC.BUSINESS.COMPANY 
    ex) anode.pod01.daejon.go.kt
        kt     -> 회사명
        go     -> 사업명(giga office)
        daejon -> 설치도시(대전)
        pod01  -> RACK명   
        anode  -> 호스트명
        
            anode  : all-in-one host
            mnode  : management host
            mnnode : management + network host
            snode  : storage host
            cnode  : compute host
            onode  : object storage host

- Host Nic Naming:
    우분투 14.04:
        1G NIC: em1, em2, em3 ~ 이런식으로 만들어짐
        10 NIC: p1p1, p1p2 ~ 이런식으로 만들어짐

# host network card 설정      
	- MGMT_NIC :: anode의 management_network_nic                              
	- EXT_NIC  :: anode의 external_network_nic
	- API_NIC  :: anode의 external_network_nic
	- GUEST_NIC:: anode의 guest_network_nic
	- LAN_NIC  :: anode의 lan_network_nic for Giga Office(green(custormer)/orange(server farm) network)
	- WAN_NIC  :: anode의 lan_network_nic for Giga Office(red: public network)                            

# host ip 설정
	- CTRL_HOST:: controller 역할을 수행하는 서버의 management_ip
	                     all_in_one 토폴로지에서는 MGMT_IP와 동일
	- MGMT_IP  :: openstack componet들의 통신을 위한 management_network_ip                        
	- API_IP   :: 외부 사용자들이 openstack api server 및 vnc 접속를 이용하기 위한 public_ip
	              주의) KT에서 사용하는 시스템들은 외부접속이 안되므로 
	                    결국 mgmt_ip를 받아사용해야 한다.

"

export DEBIAN_FRONTEND=noninteractive

echo "
# -----------------------------------------------
# Server DNS Naming Variable
# ex) Hostname.POD.LOC.BUSINESS.COMPANY
#       -> cnode01.east.dj_lab.zo.kt
# -----------------------------------------------
"

DOMAIN_COMPANY=kt
DOMAIN_BUSINESS=go                  # zero office
DOMAIN_LOC=dj                       # host geolocation
DOMAIN_POD=pod01                    # lack name
DOMAIN_POD_ANODE=anode              # all-in-one host

# cnode01.east.dj_lab.zo.kt
DOMAIN_APPENDIX=${DOMAIN_POD}.${DOMAIN_LOC}.${DOMAIN_BUSINESS}.${DOMAIN_COMPANY}

linux_ver=14.04



echo "
################################################################################
#
#   openstack install nodes topology network global variable 
#
################################################################################
"

function openstack_install_allinnode_env_for_production() {

    echo "
    # ------------------------------------------------------------------------------
    #   openstack_install_1node_env: 1대의 서버에 오픈스택 설치
    # ------------------------------------------------------------------------------
    "
    
    echo "    
    # 네트워크 인터페이스 카드 네이밍
    " 
	
	if [ "$linux_ver" = "14.04" ]; then
	    NIC1=em1
	    NIC2=em2
	    NIC3=em3
	    NIC4=em4    
	        
	    HSNIC1=p1p1
	    HSNIC2=p1p2
	            
	else
	    
	    NIC1=eth0
	    NIC2=eth1
	    NIC3=eth2
	    NIC4=eth3
	    
	    HSNIC1=eth4
	    HSNIC2=eth5
	fi

    ################################################################################
    # allinone_icehouse: NIC 4개
    #
    #   eth0   -> nat
    #   eth1   -> mgmt 
    #   eth2   -> guest
    #   eth3   -> external
    ################################################################################

    echo "
    #
    # host network card 설정      
    - MGMT_NIC :: anode의 management_network_nic                              
    - EXT_NIC  :: anode의 external_network_nic
    - API_NIC  :: anode의 external_network_nic
    - GUEST_NIC:: anode의 guest_network_nic
    - LAN_NIC  :: anode의 lan_network_nic for Giga Office(green(custormer)/orange(server farm) network)
    - WAN_NIC  :: anode의 lan_network_nic for Giga Office(red: public network)                            
    "
    
    MGMT_NIC=$NIC1                              
    EXT_NIC=$NIC2
    API_NIC=$NIC3
        
    GUEST_NIC=$NIC4
    
    LAN_NIC=$HSNIC1
    WAN_NIC=$HSNIC2
    

    echo "
    # host ip 설정
    - CTRL_HOST:: controller 역할을 수행하는 서버의 management_ip
                         all_in_one 토폴로지에서는 MGMT_IP와 동일
    - MGMT_IP  :: openstack componet들의 통신을 위한 management_network_ip                        
    - API_IP   :: 외부 사용자들이 openstack api server 및 vnc 접속를 이용하기 위한 public_ip
                  주의) KT에서 사용하는 시스템들은 외부접속이 안되므로 
                        결국 mgmt_ip를 받아사용해야 한다.
    "
    CTRL_HOST=??
    MGMT_IP=??                        
    API_IP=??
                    
}


function openstack_install_allinnode_env_for_vagrant() {

    echo "
    # ------------------------------------------------------------------------------
    #   openstack_install_1node_env: 1대의 서버에 오픈스택 설치
    # ------------------------------------------------------------------------------
    "
    
    echo "    
    # 네트워크 인터페이스 카드 네이밍
    " 
    
    # vagrant 로 Ubuntu 14.04 VM을 만들면 eth류로 naming 됨      
	NIC1=eth0
	NIC2=eth1
	NIC3=eth2
	NIC4=eth3
	NIC5=eth4	
	
	HSNIC1=eth5
	HSNIC2=eth6

    echo "
    #
    # host network card 설정      
    - MGMT_NIC :: anode의 management_network_nic                              
    - EXT_NIC  :: anode의 external_network_nic
    - API_NIC  :: anode의 external_network_nic
    - GUEST_NIC:: anode의 guest_network_nic
    - LAN_NIC  :: anode의 lan_network_nic for Giga Office(green(custormer)/orange(server-farm) network)
    - WAN_NIC  :: anode의 lan_network_nic for Giga Office(red: public network)                            
    "

    # vagrant의 경우 NIC1은 nat용으로 기본적으로 할당되어 있다.
    MGMT_NIC=$NIC2                              
    EXT_NIC=$NIC3
    API_NIC=$NIC4
    
    GUEST_NIC=$NIC5
    LAN_NIC=$HSNIC1
    WAN_NIC=$HSNIC2
    

    echo "
    # host ip 설정
    - CTRL_HOST:: controller 역할을 수행하는 서버의 management_ip
                  all_in_one 토폴로지에서는 MGMT_IP와 동일
    - MGMT_IP  :: openstack componet들의 통신을 위한 management_network_ip                        
    - API_IP   :: 외부 사용자들이 openstack api server 및 vnc 접속를 이용하기 위한 public_ip
                  주의) KT에서 사용하는 시스템들은 외부접속이 안되므로 
                        결국 mgmt_ip를 받아사용해야 한다.
    "
    MGMT_IP=$(ifconfig $MGMT_NIC | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
    API_IP=$(ifconfig $API_NIC | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
    CTRL_HOST=$MGMT_IP	
        
    if [ -z "$MGMT_IP" ]; then      
        echo "-> MGMT_IP를 설정할 수 없습니다."
        echo "   ifconfig $MGMT_NIC | awk '/inet addr/ ' "
        exit
    fi
    
    # LJG: 이게 필요한지 모르겠슴         
    # EXT_IP=$(ifconfig $EXT_NIC | awk '/inet addr/ {split ($2,A,":"); print A[2]}')

}


function topology_check() {
	echo '### check result -----------------------------------------------------'
	echo "## 네트워크 카드 설정 현황"
	printf "%30s => %-20s :: %s\n" MGMT_NIC  $MGMT_NIC  "management network nic"
	printf "%30s => %-20s :: %s\n" EXT_NIC   $EXT_NIC   "external network nic"    
	printf "%30s => %-20s :: %s\n" API_NIC   $API_NIC   "api network nic"
    printf "%30s => %-20s :: %s\n" GUEST_NIC $GUEST_NIC "guest network nic"                    
    printf "%30s => %-20s :: %s\n" LAN_NIC   $LAN_NIC   "giga office lan(custormer/server-farm) network nic"
    printf "%30s => %-20s :: %s\n" WAN_NIC   $WAN_NIC   "giga office wan(public) network nic"
    
    echo "## 네트워크 IP 설정 현황"
	printf "%30s => %-20s :: %s\n" CTRL_HOST $CTRL_HOST "controller management ip"
	printf "%30s => %-20s :: %s\n" MGMT_IP   $MGMT_IP   "host management ip"
	printf "%30s => %-20s :: %s\n" API_IP    $API_IP    "api-server ip"
	
	echo '# --------------------------------------------------------------------'
	echo "  이 설정이 맞지 않으면 제대로 설치가 안되니 정확하게 확인하세요 !!!!"
    echo '# --------------------------------------------------------------------'
    echo ""	    
	
}