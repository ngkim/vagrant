#!/bin/bash

source "./00_check_config.sh"

install_mongodb() {
	apt-get install -y mongodb-server mongodb-clients python-pymongo	
}

config_mongodb() {
	local CFG_FILE="/etc/mongodb.conf"
	
	sed -i "s/bind_ip = 127.0.0.1/bind_ip = ${CTRL_MGMT_IP}\nsmallfiles = true/g" $CFG_FILE		
}

stop_and_start_mongodb() {
	service mongodb stop
	rm /var/lib/mongodb/journal/prealloc.*
	service mongodb start
}

create_ceilometer_db() {
	mongo --host controller --eval 'db = db.getSiblingDB("ceilometer");db.addUser({user: "ceilometer", pwd: "${CEILOMETER_DBPASS}", roles: [ "readWrite", "dbAdmin" ]})'
	RESULT=$?
	
	#mongo --host controller --eval 'db = db.getSiblingDB("ceilometer");db.addUser({user: "ceilometer", pwd: "ceilometer1234", roles: [ "readWrite", "dbAdmin" ]})'
}

restart_mongodb() {
	service mongodb restart
}

#==================================================================
print_title "CEILOMETER - INSTALL - MONGODB"
#==================================================================

cmd="install_mongodb"
run_commands $cmd

cmd="config_mongodb"
run_commands $cmd

cmd="stop_and_start_mongodb"
run_commands $cmd

cmd="create_ceilometer_db"
run_commands $cmd

# if create_ceilometer_db fails, do it again
if [ $RESULT -ne 0 ]; then
  sleep 1
  cmd="create_ceilometer_db"
  run_commands $cmd
fi

cmd="restart_mongodb"
run_commands $cmd
