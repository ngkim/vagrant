#!/bin/bash

_HOSTNAME="SERVER-SLAVE"

sudo hostname $_HOSTNAME
sudo cat > /etc/hostname << EOF
$_HOSTNAME
EOF

sudo sysctl -w net.ipv4.ip_forward=1

LAN_DEV=eth1
LAN_VIP="172.16.10.100/24"
LAN_PRI=101

WAN_DEV=eth2
WAN_VIP="10.15.7.100/24"
WAN_PRI=101

SYNC_DEV=eth3
SYNC_IP_LOC=10.0.0.2
SYNC_IP_DST=10.0.0.1

sudo ifconfig eth1 172.16.10.102/24 up	
sudo ifconfig eth2 10.15.7.102/24 up	
sudo ifconfig eth3 10.0.0.2/24 up	

echo "sudo apt-get update > /dev/null"
sudo apt-get update > /dev/null
echo "sudo apt-get install -y language-pack-en language-pack-ko ifstat > /dev/null"
sudo apt-get install -y language-pack-en language-pack-ko ifstat > /dev/null
echo "sudo apt-get install -y keepalived conntrack conntrackd > /dev/null"
sudo apt-get install -y keepalived conntrack conntrackd > /dev/null

sudo cat > /etc/keepalived/keepalived.conf << EOF
vrrp_sync_group G1 {
    group {
        LAN 
        WAN
    }
    notify_master "/etc/conntrackd/primary-backup.sh primary"
    notify_backup "/etc/conntrackd/primary-backup.sh backup"
    notify_fault "/etc/conntrackd/primary-backup.sh fault"
}

vrrp_instance LAN {
    interface $LAN_DEV
    state BACKUP
    virtual_router_id 62
    priority $LAN_PRI

    use_vmac vrrp-lan
    vmac_xmit_base

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
 
    use_vmac vrrp-wan
    vmac_xmit_base

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

sudo cat > /etc/conntrackd/conntrackd.conf << EOF
Sync {
    Mode FTFW {
        DisableExternalCache Off
        CommitTimeout 1800
        PurgeTimeout 5
    }

    UDP {
        IPv4_address ${SYNC_IP_LOC}
        IPv4_Destination_Address ${SYNC_IP_DST}
        Port 3780
        Interface ${SYNC_DEV}
        SndSocketBuffer 1249280
        RcvSocketBuffer 1249280
        Checksum on
    }
}

General {
    Nice -20
    HashSize 32768
    HashLimit 131072
    LogFile on
    Syslog on
    LockFile /var/lock/conntrack.lock
    UNIX {
        Path /var/run/conntrackd.ctl
        Backlog 20
    }
    NetlinkBufferSize 2097152
    NetlinkBufferSizeMaxGrowth 8388608
    Filter From Userspace {
        Protocol Accept {
            TCP
            UDP
            ICMP # This requires a Linux kernel >= 2.6.31
        }
        Address Ignore {
            IPv4_address 127.0.0.1 # loopback
            IPv4_address 10.0.0.1
            IPv4_address 10.0.0.2
            IPv4_address 172.16.10.100
            IPv4_address 172.16.10.101
            IPv4_address 172.16.10.102
            IPv4_address 10.15.7.100
            IPv4_address 10.15.7.101
            IPv4_address 10.15.7.102
        }
    }
}
EOF

sudo cp /usr/share/doc/conntrackd/examples/sync/primary-backup.sh /etc/conntrackd

sudo sysctl -w net.ipv4.ip_nonlocal_bind=1
sudo service keepalived start

