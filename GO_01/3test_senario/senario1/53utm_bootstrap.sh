#!/bin/bash

echo "
################################################################################
#
#   UTM VM :: User Data Action
#
################################################################################
"


# ToDo List
# 1. 근본적으로는 3, 4, 5번이 리부팅이 되어도 실행되게 해야함.
#    그리고 vm을 생성할때 IP를 고정시켜야 함. 그래야 5번이 확실함.

# 2. sudo: unable to resolve host host_name 에러발생
#    /etc/hosts의 host명과 /etc/hostname의 host명이 틀릴때 나오는 메세지
#    /etc/hostname에 기입되 있는 host명을 /etc/hosts에 추가해 준다.
#    근본적으로 이렇게 만들려면 nova boot 명령이전에 
#    템플릿 기반으로 bootstrap.sh 파일을 만든 다음 이를 nova boot에 넘겨야 한다는 야그

echo "
# ---------------------------------------------------
# 0. id 확인
# ---------------------------------------------------
"
id

echo "
# ---------------------------------------------------
# 1. install bridge-utils to use brctl commands
# ---------------------------------------------------
"

apt-get -y update
apt-get -y install bridge-utils
apt-get -y install iperf    
#apt-get -y install iperf ipcalc dhcpdump htop tcpdump lsof

echo "
# --------------------------------------------------- 
# 2. ip_forward activate
# ---------------------------------------------------
"        

echo "
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0" | tee -a /etc/sysctl.conf

sysctl -p    

echo "
# --------------------------------------------------- 
# 3. green/orange nic activate
# ---------------------------------------------------
"

echo "ifconfig eth1 192.168.0.1   netmask 255.255.255.0 up"
ifconfig eth1 192.168.0.1   netmask 255.255.255.0 up
echo "ifconfig eth2 192.168.0.225 netmask 255.255.255.224 up"
ifconfig eth2 192.168.0.225 netmask 255.255.255.224 up                                
    
echo "
################################################################################
#
#   End User Data Action
#
################################################################################
"           