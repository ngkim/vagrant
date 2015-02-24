#!/bin/bash

###########################################################################
# Author: Namgon Kim
# Date: 2015. 02. 23
#
# Open vSwitch의 최신버전 (2.3.1)을 소스코드로 다운로드하여 설치
#
###########################################################################

CACHE_SERVER="211.224.204.145:23142"

###########################################################################

function run_commands() {
	_green=$(tput setaf 2)
	normal=$(tput sgr0)
	
	commands=$*
	echo -e ${_green}${commands}${normal}
	eval $commands
	echo
}

echo "1. configure apt-get proxy"

sudo cat > /etc/apt/apt.conf.d/02proxy <<EOF
Acquire::http { Proxy "http://$CACHE_SERVER"; };
EOF

echo "2. apt-get update"
sudo apt-get update
		
echo "3. update /etc/resolv.conf"
sudo cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
EOF

echo "4. install essential packages"
apt-get install -y python-simplejson \
	automake autoconf gcc \
	uml-utilities libtool \
	build-essential \
	git pkg-config
		
echo "5. download openvswitch-2.3.1.tar.gz"
# suppress output
wget http://openvswitch.org/releases/openvswitch-2.3.1.tar.gz &> /dev/null
tar xvzf openvswitch-2.3.1.tar.gz &> /dev/null
	
echo "6. compile"
cd openvswitch-2.3.1
./boot.sh
./configure --with-linux=/lib/modules/`uname -r`/build
make

echo "7. make install"
sudo make install
		
echo "8. insmod openvswitch.ko"
sudo modprobe vxlan
sudo modprobe gre
sudo modprobe libcrc32c
sudo insmod datapath/linux/openvswitch.ko

echo "9. start ovsdb-server"
sudo touch /usr/local/etc/ovs-vswitchd.conf
sudo mkdir -p /usr/local/etc/openvswitch
sudo ovsdb-tool create /usr/local/etc/openvswitch/conf.db vswitchd/vswitch.ovsschema
	
sudo ovsdb-server -v --remote=punix:/usr/local/var/run/openvswitch/db.sock \
--remote=db:Open_vSwitch,Open_vSwitch,manager_options \
--private-key=db:Open_vSwitch,SSL,private_key \
--certificate=db:Open_vSwitch,SSL,certificate \
--bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert \
--pidfile --detach

sleep 3

echo "10. start ovs-vswitchd"
sudo ovs-vsctl --no-wait init
sudo ovs-vswitchd --pidfile --detach
sudo ovs-vsctl show	