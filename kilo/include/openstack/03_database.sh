create_db() {
	DB_NAME=$1
	DB_USER=$2
	DB_PASS=$3
	
	mysql -u root -p${DB_ADMIN_PASS} -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
	mysql -u root -p${DB_ADMIN_PASS} -h localhost -e "GRANT ALL PRIVILEGES ON ${DB_USER}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${KEYSTONE_DBPASS}' WITH GRANT OPTION;"
	mysql -u root -p${DB_ADMIN_PASS} -h localhost -e "GRANT ALL PRIVILEGES ON ${DB_USER}.* TO '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}' WITH GRANT OPTION;"	
}
