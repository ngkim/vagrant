#!/bin/bash

###########################################################################
# Author: Namgon Kim
# Date: 2015. 03. 10
# 
# Desc: keepalived + vrrp_sync_group 
_HOSTNAME="SERVER-SLAVE"

LAN_DEV=eth1
LAN_PRI=140
LAN_IP_="172.16.10.102/24"
LAN_VIP="172.16.10.100/24"

WAN_DEV=eth2
WAN_PRI=140
WAN_IP_="10.15.7.102/24"
WAN_VIP="10.15.7.100/24"
###########################################################################

sudo hostname $_HOSTNAME
sudo cat > /etc/hostname << EOF
$_HOSTNAME
EOF

sudo sysctl -w net.ipv4.ip_forward=1

sudo ifconfig eth1 $LAN_IP_ up	
sudo ifconfig eth2 $WAN_IP_ up	

echo "sudo apt-get update > /dev/null"
sudo apt-get update > /dev/null
echo "sudo apt-get install -y language-pack-en language-pack-ko ifstat > /dev/null"
sudo apt-get install -y language-pack-en language-pack-ko ifstat > /dev/null
echo "sudo apt-get install -y keepalived conntrackd conntrack > /dev/null"
sudo apt-get install -y keepalived conntrackd conntrack > /dev/null

sudo cat > /etc/keepalived/keepalived.conf << EOF
vrrp_sync_group G1 {
    group {
        LAN 
        WAN
    }
}

vrrp_instance LAN {
    interface $LAN_DEV
    state BACKUP

    virtual_router_id 62
    priority $LAN_PRI

    advert_int 1
    authentication {
        auth_type PASS
        auth_pass zzzz
    }
    virtual_ipaddress {
        $LAN_VIP dev $LAN_DEV
    }
    garp_master_delay 1
}

vrrp_instance WAN {
    interface $WAN_DEV
    state BACKUP
    virtual_router_id 61
    priority $WAN_PRI

    advert_int 1
    authentication {
        auth_type PASS
        auth_pass zzzz
    }
    virtual_ipaddress {
        $WAN_VIP dev $WAN_DEV
    }
    garp_master_delay 1
}
EOF

sudo sysctl -w net.ipv4.ip_nonlocal_bind=1
sudo service keepalived start

