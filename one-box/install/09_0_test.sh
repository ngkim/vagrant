#!/bin/bash

source "./00_check_config.sh"

create_ceilometer_db() {
        local USR_ID=$1
        local USR_PASS=$2

	mongo --host controller --eval 'db = db.getSiblingDB("ceilometer");db.addUser({user: "'${USR_ID}'", pwd: "'${USR_PASS}'", roles: [ "readWrite", "dbAdmin" ]})'
	#mongo --host controller --eval 'db = db.getSiblingDB("ceilometer");db.addUser({user: "${USR_ID}", pwd: "${USR_PASS}", roles: [ "readWrite", "dbAdmin" ]})'
	RESULT=$?
	
	#mongo --host controller --eval 'db = db.getSiblingDB("ceilometer");db.addUser({user: "ceilometer", pwd: "ceilometer1234", roles: [ "readWrite", "dbAdmin" ]})'
}

connect_ceilometer_db() {
        local USR_ID=$1
        local USR_PASS=$2
        local CEIL_DB=$3

	#mongo --host controller -u $USR_ID -p $USR_PASS $CEIL_DB --eval "db.runCommand(show dbs);"
	#mongo --host controller -u $USR_ID -p $USR_PASS $CEIL_DB --eval "printjson(db.serverStatus())"
	mongo --host controller -u $USR_ID -p $USR_PASS $CEIL_DB --eval "print(\"login success!\");"
	RESULT=$?
}

restart_mongodb() {
	service mongodb restart
}

#==================================================================
print_title "CEILOMETER - INSTALL - MONGODB"
#==================================================================

cmd="create_ceilometer_db ceil ceilo1234"
run_commands $cmd

# if create_ceilometer_db fails, do it again
#if [ $RESULT -ne 0 ]; then
#  sleep 1
#  cmd="create_ceilometer_db"
#  run_commands $cmd
#else
  cmd="connect_ceilometer_db ceil ceilo1234 ceilometer"
  run_commands $cmd
 
  if [ $RESULT -ne 0 ]; then
    echo "RESULT= $RESULT"
  fi

#fi

