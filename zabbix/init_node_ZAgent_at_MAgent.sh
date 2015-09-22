#!/bin/bash

source "include/print_util.sh"

####################################################
# configurations 
####################################################
SV_ADDR="211.224.204.202/24"
DB_PASS="ohhberry3333"
#---------------------------------------------------
ZAB_AGENTD_CFG="/etc/zabbix/zabbix_agentd.conf"
####################################################

####################################################
# functions
####################################################
list_archives() {
}

####################################################

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


