#! /bin/bash

openvswitch_install() {

    echo '
    # ------------------------------------------------------------------------------
    ### openvswitch_install() !!!
    # ------------------------------------------------------------------------------'
  
    echo "apt-get -y install linux-headers-`uname -r`"
    
    apt-get -y install \
    	linux-headers-`uname -r`
    	
    apt-get -y install \
        vlan \
        bridge-utils build-essential\
        dnsmasq-base dnsmasq-utils \
        openvswitch-switch

    echo 'openvswitch-switch 시작 !!!'
    /etc/init.d/openvswitch-switch restart

    echo '>>> check result'
    echo '# -------------------------------------------------------------------'    
    dpkg -l | egrep "linux-headers-`uname -r`"
    dpkg -l | egrep "vlan|bridge-utils|dnsmasq-base|dnsmasq-utils|openvswitch-switch"    
    echo '# -------------------------------------------------------------------'

}

openvswitch_execute() {
    echo '
    # -------------------------------------------------------------------------
    ### openvswitch_execute() !!!
    # -------------------------------------------------------------------------'
        
    echo '# openvswitch-switch 구성 !!!'    
    
    echo "  -> ovs-vsctl add-br $LOG_INT_BR"
    ovs-vsctl add-br $LOG_INT_BR
    
    # guest network
    echo "  -> ovs-vsctl add-br $LOG_GUEST_BR"
    ovs-vsctl add-br $LOG_GUEST_BR
    echo "  -> ovs-vsctl add-port $LOG_GUEST_BR $GUEST_NIC"
    ovs-vsctl add-port $LOG_GUEST_BR $GUEST_NIC
    
    # lan network
    echo "  -> ovs-vsctl add-br $LOG_LAN_BR"
    ovs-vsctl add-br $LOG_LAN_BR
    echo "  -> ovs-vsctl add-port $LOG_LAN_BR $LAN_NIC"
    ovs-vsctl add-port $LOG_LAN_BR $LAN_NIC
    
    # wan network
    echo "  -> ovs-vsctl add-br $LOG_WAN_BR"
    ovs-vsctl add-br $LOG_WAN_BR
    echo "  -> ovs-vsctl add-port $LOG_WAN_BR $WAN_NIC"
    ovs-vsctl add-port $LOG_WAN_BR $WAN_NIC    
    
    # external network
    echo "  -> ovs-vsctl add-br $LOG_EXT_BR"
    ovs-vsctl add-br $LOG_EXT_BR
    echo "  -> ovs-vsctl add-port $LOG_EXT_BR $EXT_NIC"
    ovs-vsctl add-port $LOG_EXT_BR $EXT_NIC        
    
    # 외부 접속을 지원하기 위해 ext bridge에 IP를 할당한다.
    # ex) ifconfig br-ex 192.168.100.11 netmask 255.255.255.0
    #echo "  -> ifconfig $LOG_EXT_BR $EXT_IP netmask 255.255.255.0"     
    #ifconfig $LOG_EXT_BR $EXT_IP netmask 255.255.255.0
    
    echo '>>> check result'
    echo '# -------------------------------------------------------------------'
    ovs-vsctl show
    ip a
    echo '# -------------------------------------------------------------------'
}
