#!/bin/bash

##########################################################################################################
# REFERENCES
# - http://blog.themilkyway.org/2013/11/how-to-monitor-mysql-using-the-new-zabbix-template-app-mysql/
##########################################################################################################

ROOT_PASS="ohhberry3333"

add_zabbix_account() {
  mysql -uroot -p${ROOT_PASS} -e"GRANT USAGE ON *.* TO 'zabbix'@'127.0.0.1' IDENTIFIED BY '${ROOT_PASS}'";
  mysql -uroot -p${ROOT_PASS} -e"GRANT USAGE ON *.* TO 'zabbix'@'localhost' IDENTIFIED BY '${ROOT_PASS}'";
  mysql -uroot -p${ROOT_PASS} -e"flush privileges"
  mysql -uzabbix -p${ROOT_PASS} -e"status"
}

config_zabbix_mysql() {
 cat > /etc/zabbix/.my.cnf <<EOF
[mysql]
user=zabbix
password=${ROOT_PASS}
[mysqladmin]
user=zabbix
password=${ROOT_PASS}
EOF
}

copy_zbbix_mysql_conf() {
  cp /usr/share/doc/zabbix-agent/examples/userparameter_mysql.conf /etc/zabbix/zabbix_agentd.conf.d/
}

restart_zabbix_agent() {
  service zabbix-agent restart
}

#add_zabbix_account
#config_zabbix_mysql
copy_zbbix_mysql_conf
restart_zabbix_agent
