#!/bin/bash

source "../config/default.cfg"
source "../include/print_util.sh"
source "../include/12_config.sh"

install_mongodb() {
	apt-get install -y mongodb-server mongodb-clients python-pymongo	
}

config_mongodb() {
	local CFG_FILE="/etc/mongodb.conf"
	
	bind_ip = ${CTRL_MGMT_IP}
	smallfiles = true	
}

create_ceilometer_db() {
	mongo --host controller --eval '
	db = db.getSiblingDB("ceilometer");
	db.addUser({user: "ceilometer", pwd: "${CEILOMETER_DBPASS}", roles: [ "readWrite", "dbAdmin" ]})'
}

stop_and_start_mongodb() {
	service mongodb stop
	rm /var/lib/mongodb/journal/prealloc.*
	service mongodb start
}

restart_mongodb() {
	service mongodb restart
}

#==================================================================
print_title "CEILOMETER - INSTALL - MONGODB"
#==================================================================

install_mongodb
config_mongodb
create_ceilometer_db
stop_and_start_mongodb
restart_mongodb