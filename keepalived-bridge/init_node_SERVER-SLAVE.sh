#!/bin/bash

sudo ifconfig eth1 192.168.0.253/24 up	

sudo apt-get update
sudo apt-get install -y keepalived

sudo cat > /etc/keepalived/keepalived.conf << EOF
global_defs {
  router_id haproxy1
}

vrrp_script haproxy {
  script "killall -0 haproxy"
  interval 2
  weight 2
}

vrrp_instance 50 {
  state MASTER
  interface eth1

  virtual_router_id 50
  priority 100
  advert_int 1

  virtual_ipaddress {
    192.168.0.254
  }

  track_script {
    haproxy
  }
}
EOF

sudo sysctl -w net.ipv4.ip_nonlocal_bind=1
sudo service keepalived start
