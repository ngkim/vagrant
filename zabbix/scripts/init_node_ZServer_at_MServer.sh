#!/bin/bash

source "include/print_util.sh"

####################################################
# configurations 
####################################################
DB_PASS="ohhberry3333"
#---------------------------------------------------
PHP_INI="/etc/php5/apache2/php.ini"
ZAB_CONF_PHP="/etc/zabbix/zabbix.conf.php"
ZAB_WEB_CONF_USR="/usr/share/zabbix/conf/zabbix.conf.php"
ZAB_WEB_CONF_DIR="/etc/zabbix/web"
ZAB_WEB_CONF_ETC="/etc/zabbix/web/zabbix.conf.php"
####################################################

####################################################
# functions
####################################################

install_db() {
  export DEBIAN_FRONTEND=noninteractive
  echo mysql-server-5.5 mysql-server/root_password password ${DB_PASS} | sudo debconf-set-selections
  echo mysql-server-5.5 mysql-server/root_password_again password ${DB_PASS} | sudo debconf-set-selections
  sudo apt-get -y install mysql-server-5.5
}

install_zabbix-db() {
echo "zabbix-server-mysql zabbix-server-mysql/dbconfig-install boolean true" | debconf-set-selections
echo "zabbix-server-mysql zabbix-server-mysql/mysql/admin-pass password ${DB_PASS}" | debconf-set-selections
echo "zabbix-server-mysql zabbix-server-mysql/mysql/app-pass password ${DB_PASS}" | debconf-set-selections
echo "zabbix-server-mysql zabbix-server-mysql/password-confirm password ${DB_PASS}" | debconf-set-selections
/usr/bin/mysqld_safe & apt-get install -y zabbix-server-mysql
}
####################################################

####################################################
print_msg "2. install APM"
####################################################
sudo apt-get update
sudo apt-get -y install apache2 

install_db

sudo apt-get -y install php5 php5-cli php5-common php5-mysql

####################################################
print_msg "3. start APM"
####################################################
/etc/init.d/apache2 start
/etc/init.d/mysql start

####################################################
print_msg "4. add zabbix repository"
####################################################
wget http://repo.zabbix.com/zabbix/2.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_2.2-1+trusty_all.deb
sudo dpkg -i zabbix-release_2.2-1+trusty_all.deb
sudo apt-get update

####################################################
print_msg "5. install zabbix" 
####################################################
install_zabbix-db
sudo apt-get -y install zabbix-frontend-php

####################################################
print_msg "6. edit the Zabbix init file to ensure that it performs the correct action"
####################################################
echo "START=yes" > /etc/default/zabbix-server

####################################################
print_msg "7. adjust php.ini file as per zabbix recommended settings"
####################################################
sed -i "s/post_max_size = 8M/post_max_size = 16M/g" $PHP_INI
sed -i "s/max_execution_time = 30/max_execution_time = 300/g" $PHP_INI
sed -i "s/max_input_time = 60/max_input_time = 300/g" $PHP_INI
sed -i "s/;date.timezone =/date.timezone = \"Asia\/Seoul\"/g" $PHP_INI

####################################################
print_msg "8. adjust ${ZAB_CONF_PHP}"
####################################################
cp /usr/share/zabbix/conf/zabbix.conf.php.example ${ZAB_CONF_PHP}
sed -i "s/zabbix_password/${DB_PASS}/g" ${ZAB_CONF_PHP}
sed -i "s/\$ZBX_SERVER_NAME\t\t= ''/\$ZBX_SERVER_NAME\t\t= 'Zabbix-Server'/" ${ZAB_CONF_PHP}

####################################################
print_msg "8-1. create web configuration"
####################################################
mkdir -p  $ZAB_WEB_CONF_DIR
cp ${ZAB_CONF_PHP} ${ZAB_WEB_CONF_ETC}
ln -s ${ZAB_WEB_CONF_ETC} ${ZAB_WEB_CONF_USR}


####################################################
print_msg "9. restart zabbix-server"
####################################################
sudo service zabbix-server restart

####################################################
print_msg "10. restart apache2"
####################################################
sudo service apache2 restart

####################################################
print_msg "*** Zabbix Web: http://localhost/zabbix (Admin/zabbix)"
####################################################
