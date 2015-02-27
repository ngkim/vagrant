#!/bin/bash

echo "
################################################################################
#
#   Global Management VM :: User Data Action
#
################################################################################
"


echo "
# ---------------------------------------------------
# 1. install linux utils
# ---------------------------------------------------
"

date

apt-get -y update   
apt-get -y install ipcalc iperf dhcpdump htop ngrep nmap dstat ifstat sysstat ethtool


echo "
# --------------------------------------------------- 
# 2. install python utils
# ---------------------------------------------------
"

apt-get install python-all-dev
apt-get -y install python-pip
apt-get -y install python-mysqldb

pip install pexpect
pip install twisted
pip freeze | sort

date
    
echo "
################################################################################
#
#   End Global Management VM
#
################################################################################
"
            