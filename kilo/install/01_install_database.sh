#!/bin/bash

source "/vagrant/config/default.cfg"
source "/vagrant/include/print_util.sh"
source "/vagrant/include/12_config.sh"

#-----------------------------------------------------------------------------------------------------------------------
print_title "DATABASE" 
#-----------------------------------------------------------------------------------------------------------------------

install_db() {
	export DEBIAN_FRONTEND=noninteractive
	echo mariadb-server-5.5 mariadb-server/root_password password ${DB_ADMIN_PASS} | debconf-set-selections
	echo mariadb-server-5.5 mysql-server/root_password password ${DB_ADMIN_PASS} | debconf-set-selections
	echo mariadb-server-5.5 mysql-server/root_password_again password ${DB_ADMIN_PASS} | debconf-set-selections
	
	apt-get install -y mariadb-server python-mysqldb	
}

config_db() {
	print_title "/etc/mysql/conf.d/mysqld_openstack.cnf"
	
	cat > /etc/mysql/conf.d/mysqld_openstack.cnf <<EOF
[mysqld]
bind-address = ${CTRL_MGMT_IP}
default-storage-engine = innodb
innodb_file_per_table
collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8
EOF
}

restart_db() {
	service mysql restart
}

secure_db_install() {
	#---------------------------------------------------------------------------------
	# mysql_secure_installation
	#---------------------------------------------------------------------------------

	# run following commands instead of mysql_secure_installation
	#---------------------------------------------------------------------------------
	# Make sure that NOBODY can access the server without a password
	mysql -u root -p${DB_ADMIN_PASS} -e "UPDATE mysql.user SET Password = PASSWORD('${DB_ADMIN_PASS}') WHERE User = 'root'"

	# remove_anonymous_users
	mysql -u root -p${DB_ADMIN_PASS} -e "DELETE FROM mysql.user WHERE User=''"
	
	# remove_remote_root
	mysql -u root -p${DB_ADMIN_PASS} -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"

	# remove_test_database
	mysql -u root -p${DB_ADMIN_PASS} -e "DROP DATABASE IF EXISTS test;"
	
	# Make our changes take effect
	mysql -u root -p${DB_ADMIN_PASS} -e "FLUSH PRIVILEGES"
	# Any subsequent tries to run queries this way will get access denied because lack of usr/pwd param
	#---------------------------------------------------------------------------------
}

install_db
config_db
restart_db
secure_db_install
