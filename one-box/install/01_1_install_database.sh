#!/bin/bash

source "./00_check_config.sh"

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
bind-address = 0.0.0.0
default-storage-engine = innodb
innodb_file_per_table
collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8
max_connections = 2000
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
	# remove_anonymous_users
	# remove_remote_root
	# remove_test_database
	mysql -u root -p${DB_ADMIN_PASS} -e "UPDATE mysql.user SET Password = PASSWORD('${DB_ADMIN_PASS}') WHERE User = 'root'"
	mysql -u root -p${DB_ADMIN_PASS} -e "DELETE FROM mysql.user WHERE User=''"
	mysql -u root -p${DB_ADMIN_PASS} -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
	mysql -u root -p${DB_ADMIN_PASS} -e "DROP DATABASE IF EXISTS test;"
	mysql -u root -p${DB_ADMIN_PASS} -e "FLUSH PRIVILEGES"
	
	# Make our changes take effect
	#mysql -u root -e "UPDATE mysql.user SET Password = PASSWORD('${DB_ADMIN_PASS}') WHERE User = 'root'"
	#mysql -u root -e "DELETE FROM mysql.user WHERE User=''"
	#mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
	#mysql -u root -e "DROP DATABASE IF EXISTS test;"
	#mysql -u root -e "FLUSH PRIVILEGES"
	# Any subsequent tries to run queries this way will get access denied because lack of usr/pwd param
	#---------------------------------------------------------------------------------
}

install_db
config_db
restart_db
secure_db_install
