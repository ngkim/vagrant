source "$WORK_HOME/include/command_util.sh"

create_db() {
	DB_NAME=$1
	DB_USER=$2
	DB_PASS=$3
	
	cmd="mysql -u root -p${DB_ADMIN_PASS} -e \"CREATE DATABASE IF NOT EXISTS ${DB_NAME};\""
	run_commands $cmd
	
	mysql -u root -p${DB_ADMIN_PASS} -h localhost -e "GRANT ALL PRIVILEGES ON ${DB_USER}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${KEYSTONE_DBPASS}' WITH GRANT OPTION;"
	mysql -u root -p${DB_ADMIN_PASS} -h localhost -e "GRANT ALL PRIVILEGES ON ${DB_USER}.* TO '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}' WITH GRANT OPTION;"
	
	cmd="mysql -u ${DB_USER} -p ${DB_PASS} -h localhost $DB_NAME -e \"show tables\""
	if [ $? -ne 0 ]; then
		print_msg_high "ERROR: Failed to connect to $DB_NAME"
		exit
	fi
}
