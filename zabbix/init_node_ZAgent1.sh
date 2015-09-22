#!/bin/bash

source "include/print_util.sh"

####################################################
# configurations 
####################################################
SV_ADDR="192.168.10.1/24"
IP_ADDR="192.168.10.2/24"
DB_PASS="ohhberry3333"
#---------------------------------------------------
ZAB_AGENTD_CFG="/etc/zabbix/zabbix_agentd.conf"
####################################################

####################################################
# functions
####################################################
mkdir -p /vagrant/list-agent
list_archives() {
  STR=$1

  ls -t /var/cache/apt/archives/*.deb > /vagrant/list-agent/$STR.list
}

####################################################

####################################################
print_msg "1. network configuration"
####################################################
sudo ifconfig eth1 ${IP_ADDR} up
list_archives STEP0

####################################################
print_msg "2. install zabbix-agent"
####################################################
sudo apt-get update
sudo apt-get install -y zabbix-agent
list_archives STEP1

####################################################
print_msg "3. configure zabbix-agentd"
####################################################
sed -i "s/Server=127.0.0.1/Server=${SV_ADDR}/g" $ZAB_AGENTD_CFG
#sudo nano $ZAB_AGENTD_CFG

####################################################
print_msg "4. reetart zabbix-agent"
####################################################
sudo service zabbix-agent restart


