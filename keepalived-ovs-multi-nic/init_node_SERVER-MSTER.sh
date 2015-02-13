#!/bin/bash

sudo brctl addbr br0
sudo ifconfig br0 192.168.0.252/24 up
sudo brctl addif br0 eth1
sudo brctl addif br0 eth2

sudo ifconfig eth1 up
sudo ifconfig eth2 up
sudo ifconfig eth3 221.145.180.21/24 up	

sudo apt-get update
sudo apt-get install -y keepalived

sudo cat > /etc/keepalived/keepalived.conf << EOF
global_defs {
  router_id haproxy1
}

vrrp_sync_group VG1{
  VI_LAN
  VI_WAN
}

vrrp_instance VI_LAN {
  state MASTER
  interface br0

  virtual_router_id 50
  priority 101
  advert_int 1

  track_interface { 
    eth1 
    eth2
  }

  virtual_ipaddress {
    192.168.0.254/24  brd 192.168.0.255   dev br0
  }

}

vrrp_instance VI_WAN {
  state MASTER
  interface eth3

  virtual_router_id 50
  priority 101
  advert_int 1

  track_interface { 
    eth3
  }

  virtual_ipaddress {
    221.145.180.20/24 brd 221.145.180.255 dev eth3
  }

}
EOF

sudo sysctl -w net.ipv4.ip_nonlocal_bind=1
sudo service keepalived start
