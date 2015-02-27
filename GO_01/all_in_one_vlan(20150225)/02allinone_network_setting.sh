#!/bin/bash

function all_in_one_hosts_info_setting() {

    echo "
    # ------------------------------------------------------------------------------
    # 호스트 정보 등록 in /etc/hosts !!!
    # ------------------------------------------------------------------------------"
    
    backup_org /etc/hosts
    
cat > /etc/hosts <<EOF
${CTRL_HOST}  ${DOMAIN_POD_ANODE}   ${DOMAIN_POD_ANODE}.${DOMAIN_APPENDIX}
EOF
    echo "cat /etc/hosts"        
    cat /etc/hosts

    echo "
    # ------------------------------------------------------------------------------
    # 호스트 이름 등록 in /etc/hostname !!!
    # ------------------------------------------------------------------------------"

    backup_org /etc/hostname

cat > /etc/hostname <<EOF
$DOMAIN_POD_ANODE
EOF
    
    echo "cat /etc/hostname"
    cat /etc/hostname
    
}            


################################################################################
# 하나의 node에 모두 설치
################################################################################
function all_in_one_NIC_setting_for_production() {    
    
	_nic_conf="/etc/network/interfaces"
	
	_mgmt_nic=$1
	_mgmt_ip=$2
	_mgmt_subnet_mask=$3
	
	_api_nic=$4
	_api_ip=$5
	_api_subnet_mask=$6
	_api_gw=$7
	_api_dns=$8
	
	_ext_nic=$9
	_guest_nic=${10}
	_hbrd_nic=${11}

    echo "
    # ------------------------------------------------------------------------------
    ### all_in_one_NIC_setting(${_nic_conf}) !!!
    # ------------------------------------------------------------------------------"
    
    backup_org ${_nic_conf}

# reboot 되어도 network환경이 적용되도록 설정

cat > ${_nic_conf}<<EOF
# ------------------------------------------------------------------------------
# The loopback network interface
auto lo
iface lo inet loopback

# management network
auto $_mgmt_nic
iface $_mgmt_nic inet static
    address $_mgmt_ip
    netmask $_mgmt_subnet_mask

# api network
auto $_api_nic
iface $_api_nic inet static
    address $_api_ip
    netmask $_api_subnet_mask
    gateway $_api_gw
    # dns-* options are implemented by the resolvconf package, if installed
    dns-nameservers $_api_dns

# external network        
auto $_ext_nic
iface $_ext_nic inet manual
    up ip link set dev \$IFACE up
    down ip link set dev \$IFACE down

# guest network
auto $_guest_nic
iface $_guest_nic inet manual
    up ip link set dev \$IFACE up
    down ip link set dev \$IFACE down

# hybrid network
auto $_hbrd_nic
iface $_hbrd_nic inet manual
    up ip link set dev \$IFACE up
    down ip link set dev \$IFACE down
    
EOF

    cat ${_nic_conf}

    ask_continue_stop

    ifconfig $_mgmt_nic $_mgmt_ip netmask $_mgmt_subnet_mask up
    ifconfig $_api_nic  $_api_ip  netmask $_api_subnet_mask up
    ifconfig $_ext_nic   0.0.0.0 up
    ifconfig $_guest_nic 0.0.0.0 up
    ifconfig $_hbrd_nic  0.0.0.0 up
        
    # public nic에 default gw 설정
    route add default gw $_api_gw dev $_api_nic
    
    # dns 설정
    echo "nameserver $_api_dns" | tee -a /etc/resolv.conf

    echo "
    # ------------------------------------------------------------------------------
    # 네트워크 설정 확인 !!!
    # ------------------------------------------------------------------------------"
    route -n
    echo "----------------------------------------------------------------------"
    ip a | grep UP
    echo "----------------------------------------------------------------------"
    ifconfig
    echo "----------------------------------------------------------------------"
}

################################################################################
# vagrant를 이용하여 하나의 node에 모두 설치
################################################################################
function all_in_one_NIC_setting_for_vagrant() {    
    
    echo "
        # ------------------------------------------------------------------------------
        # vagrant 사용시 적용
	
        # LJG: 물리NIC에 브릿지를 생성하기 위해서
        #      물리NIC의 IP를 삭제하고 NIC을 promisc 모드로 생성
	
        # management nic(eth1)
		box.vm.network "private_network", ip: "172.16.0.#{ip_start}", netmask: "255.255.0.0"                        
        # external nic(eth2) -> LJG: 이게 어떻게 외부와 통신이 되는지는 파악해봐야 겠다.
		box.vm.network "private_network", ip: "192.168.100.#{ip_start}",netmask: "255.255.255.0"        
        # api nic(eth3)
		box.vm.network "private_network", ip: "192.168.110.#{ip_start}",netmask: "255.255.255.0"        
        # guest nic(eth4) 
		box.vm.network "private_network", ip: "10.10.0.#{ip_start}",   netmask: "255.255.255.0"     
        # lan nic(eth5) 
		box.vm.network "private_network", ip: "10.10.10.#{ip_start}",   netmask: "255.255.255.0"        
        # wan nic(eth6) 
		box.vm.network "private_network", ip: "10.10.20.#{ip_start}",   netmask: "255.255.255.0"
		            
		이를 위해서는 vagrant가 설치시 미리 해당 NIC들(guest nic, ext nic)에 대해
		promisc 모드를 적용했어야 한다.
		ex)
		    # ext nic
		    vbox.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
		    # guest nic
		    vbox.customize ["modifyvm", :id, "--nicpromisc5", "allow-all"]
		    # lan nic
		    vbox.customize ["modifyvm", :id, "--nicpromisc6", "allow-all"]
		    # wan nic
		    vbox.customize ["modifyvm", :id, "--nicpromisc7", "allow-all"]            
    "
	
	ask_continue_stop    
	
	# ext nic에 할당된 IP를 지우고 enable 시킴
    echo "sudo ifconfig $EXT_NIC 0.0.0.0 up"
	sudo ifconfig $EXT_NIC 0.0.0.0 up
    # ext nic traffic을 다른 nic에 모두 전파시키도록 설정
    echo "sudo ip link set $EXT_NIC promisc on" 
	sudo ip link set $EXT_NIC promisc on
	    
    # guest nic에 할당된 IP를 지우고 enable 시킴
    echo "sudo ifconfig $GUEST_NIC 0.0.0.0 up"
	sudo ifconfig $GUEST_NIC 0.0.0.0 up
    # guest nic traffic을 다른 nic에 모두 전파시키도록 설정
    echo "sudo ip link set $GUEST_NIC promisc on"
	sudo ip link set $GUEST_NIC promisc on
	    
    # lan nic에 할당된 IP를 지우고 enable 시킴
    echo "sudo ifconfig $LAN_NIC 0.0.0.0 up"
	sudo ifconfig $LAN_NIC 0.0.0.0 up
    # lan nic traffic을 다른 nic에 모두 전파시키도록 설정
    echo "sudo ip link set $LAN_NIC promisc on"
	sudo ip link set $LAN_NIC promisc on    
	
	# wan nic에 할당된 IP를 지우고 enable 시킴
    echo "sudo ifconfig $WAN_NIC 0.0.0.0 up"
	sudo ifconfig $WAN_NIC 0.0.0.0 up
    # wan nic traffic을 다른 nic에 모두 전파시키도록 설정
    echo "sudo ip link set $WAN_NIC promisc on"
	sudo ip link set $WAN_NIC promisc on        
    
    ask_continue_stop
    
    echo "
    # ------------------------------------------------------------------------------
    # 네트워크 설정 확인 !!!
    # ------------------------------------------------------------------------------"
    route -n
    echo "----------------------------------------------------------------------"
    ip a | grep UP
    echo "----------------------------------------------------------------------"
    ifconfig
    echo "----------------------------------------------------------------------"
    
    ask_continue_stop
}