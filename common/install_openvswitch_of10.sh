#!/bin/bash

###########################################################################
# Author: Namgon Kim
# Date: 2015. 03. 28
#
# Open vSwitch의 최신버전 (2.3.1)을 apt-get을 이용해  설치
#
###########################################################################

###########################################################################

function run_commands() {
	_green=$(tput setaf 2)
	normal=$(tput sgr0)
	
	commands=$*
	echo -e ${_green}${commands}${normal}
	eval $commands
	echo
}

echo "1. apt-get update"
sudo sed 's@us.archive.ubuntu.com@ftp.daum.net@' -i /etc/apt/sources.list
sudo sed 's@archive.ubuntu.com@ftp.daum.net@' -i /etc/apt/sources.list
sudo sed 's@security.ubuntu.com@ftp.daum.net@' -i /etc/apt/sources.list 
sudo apt-get update

echo "2. update /etc/resolv.conf"
sudo cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
EOF

echo "3. install essential packages"
sudo apt-get install -y python-simplejson \
	automake autoconf gcc \
	uml-utilities libtool \
	build-essential \
	git pkg-config

echo "4. install openvswitch service"
sudo apt-get install -y openvswitch-switch

echo "5. resetart openvswitch service"
sudo service openvswitch-switch restart

