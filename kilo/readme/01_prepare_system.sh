#!bin/bash

source "/vagrant/config/default.cfg"
source "/vagrant/include/print_util.sh"

init_network_interfaces() {
	print_title "/etc/network/interfaces"
	
	cat > /etc/network/interfaces<<EOF
# ------------------------------------------------------------------------------
# The loopback network interface
auto lo
iface lo inet loopback

source /etc/network/interfaces.d/*.cfg
EOF
}

config_external_interface() {
	local NIC=$1
	
	print_title "external network interface: $NIC"
	
	cat > /etc/network/interfaces.d/$NIC.cfg <<EOF
auto $NIC
iface $NIC inet manual
    up ip link set dev \$IFACE up
    down ip link set dev \$IFACE down
EOF

}

config_mgmt_interface() {
	local NIC=$1
	local MGMT_IP=$2
	local MGMT_SBNET=$3
	
	print_title "management network interface: $NIC"
	
	cat > <<EOF
# management network
auto $NIC
iface $NIC inet static
    address $_mgmt_ip
    netmask $_mgmt_subnet_mask
EOF
}

config_mgmt_interface eth1 10.0.0.11 255.255.255.0

config_hosts() {
	print_title "/etc/hosts"
	
	cat > /etc/hosts <<EOF
127.0.0.1 localhost
${CTRL_MGMT_IP} controller
EOF

}

init_network_interfaces
config_external_interface $EXT_NIC
config_hosts

tmp() {
	apt-get -y install ntp
/etc/ntp.conf 파일 수정

	server ntp.ubuntu.com iburst	

rm -rf /var/lib/ntp/ntp.conf.dhcp
service ntp restart

apt-get install -y ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" \
  "trusty-updates/kilo main" > /etc/apt/sources.list.d/cloudarchive-kilo.list
  
apt-get update && apt-get dist-upgrade -y

#-----------------------------------------------------------------------------------------------------------------------
print_title "2. DB" 
#-----------------------------------------------------------------------------------------------------------------------

apt-get install -y mariadb-server python-mysqldb

mysqld_openstack() {
	print_title "/etc/mysql/conf.d/mysqld_openstack.cnf"
	
	cat > /etc/mysql/conf.d/mysqld_openstack.cnf <<EOF
[mysqld]
bind-address = 10.0.0.11
default-storage-engine = innodb
innodb_file_per_table
collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8
EOF

service mysql restart

}

mysql_secure_installation
		
#-----------------------------------------------------------------------------------------------------------------------
print_title "3. Message queue"
#-----------------------------------------------------------------------------------------------------------------------

apt-get install -y rabbitmq-server

rabbitmqctl add_user openstack ${RABBIT_PASS}
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

#==================================================================
print_title "4. Keystone"
#==================================================================

create_keystone_db() {
	mysql -u root -p${DB_ADMIN_PASS} -e "CREATE DATABASE keystone;"
	mysql -u root -p${DB_ADMIN_PASS} -h localhost -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${KEYSTONE_DBPASS}' WITH GRANT OPTION;"
	mysql -u root -p${DB_ADMIN_PASS} -h localhost -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${KEYSTONE_DBPASS}' WITH GRANT OPTION;"
}

echo "manual" > /etc/init/keystone.override
 
apt-get install -y keystone python-openstackclient apache2 libapache2-mod-wsgi memcached python-memcache

config_keystone() { 
	echo "*** config_keystone"
	
	cat > /etc/keystone/keystone.conf <<EOF
[DEFAULT]
admin_token = ${ADMIN_TOKEN}
verbose = True

[database]
connection = mysql://keystone:${KEYSTONE_DBPASS}@controller/keystone

[memcache]
servers = localhost:11211

[token]
provider = keystone.token.providers.uuid.Provider
driver = keystone.token.persistence.backends.memcache.Token

[revoke]
driver = keystone.contrib.revoke.backends.sql.Revoke
EOF

}

# su -s /bin/sh -c "keystone-manage db_sync" keystone

* /etc/apache2/apache2.conf
 -----------------------------------------------------------------------------------------------------------------------
 ServerName controller
 -----------------------------------------------------------------------------------------------------------------------
 
 * /etc/apache2/sites-available/wsgi-keystone.conf
 -----------------------------------------------------------------------------------------------------------------------
Listen 5000
Listen 35357

<VirtualHost *:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /var/www/cgi-bin/keystone/main
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    LogLevel info
    ErrorLog /var/log/apache2/keystone-error.log
    CustomLog /var/log/apache2/keystone-access.log combined
</VirtualHost>

<VirtualHost *:35357>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /var/www/cgi-bin/keystone/admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    LogLevel info
    ErrorLog /var/log/apache2/keystone-error.log
    CustomLog /var/log/apache2/keystone-access.log combined
</VirtualHost>
 -----------------------------------------------------------------------------------------------------------------------

# ln -s /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-enabled
# mkdir -p /var/www/cgi-bin/keystone
# curl http://git.openstack.org/cgit/openstack/keystone/plain/httpd/keystone.py?h=stable/kilo \
  | tee /var/www/cgi-bin/keystone/main /var/www/cgi-bin/keystone/admin
# chown -R keystone:keystone /var/www/cgi-bin/keystone
# chmod 755 /var/www/cgi-bin/keystone/*

# service apache2 restart
# rm -f /var/lib/keystone/keystone.db

	4. 2 Create the service entity and API endpoint
==================================================================

* 사전준비
# export OS_TOKEN=${ADMIN_TOKEN}
# export OS_URL=http://controller:35357/v2.0

* To create the service entity and API endpoint

openstack service create \
  --name keystone --description "OpenStack Identity" identity
  
openstack endpoint create \
  --publicurl http://controller:5000/v2.0 \
  --internalurl http://controller:5000/v2.0 \
  --adminurl http://controller:35357/v2.0 \
  --region ${REGION_NAME} \
  identity  

	4. 3 Create projects, users, and roles
==================================================================

openstack project create --description "Admin Project" admin
openstack user create --password-prompt admin
openstack role create admin
openstack role add --project admin --user admin admin

openstack project create --description "Service Project" service
openstack project create --description "Demo Project" demo
openstack user create --password-prompt demo
openstack role create user
openstack role add --project demo --user demo user

	4. 4 Verify operation
==================================================================

For security reasons, disable the temporary authentication token mechanism:

Edit the /etc/keystone/keystone-paste.ini file 
and remove admin_token_auth from the [pipeline:public_api], [pipeline:admin_api], and [pipeline:api_v3] sections.

# unset OS_TOKEN OS_URL

openstack --os-auth-url http://controller:35357 \
  --os-project-domain-id default --os-user-domain-id default \
  --os-project-name admin --os-username admin --os-auth-type password \
  token issue  
  
openstack --os-auth-url http://controller:35357 \
  --os-project-name admin --os-username admin --os-auth-type password \
  project list  

openstack --os-auth-url http://controller:35357 \
  --os-project-name admin --os-username admin --os-auth-type password \
  user list
  
	4. 5 Create OpenStack client environment scripts  
================================================================== 

1) admin-openrc.sh
-----------------------------------------------------------------------------------------------------------------------
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=${ADMIN_PASS}
export OS_AUTH_URL=http://controller:35357/v3
 ----------------------------------------------------------------------------------------------------------------------- 
 
 2) source admin-openrc.sh
 
3) openstack token issue
}
