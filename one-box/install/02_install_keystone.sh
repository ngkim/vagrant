#!/bin/bash

source "./00_check_config.sh"
source "$WORK_HOME/include/openstack/03_database.sh"

#==================================================================
print_title "KEYSTONE INSTALL Keystone"
#==================================================================

install_keystone() {
	# to disable keystone after installation
	echo "manual" > /etc/init/keystone.override
	apt-get install -y keystone python-openstackclient apache2 libapache2-mod-wsgi memcached python-memcache
}

config_keystone() { 
	set_config /etc/keystone/keystone.conf DEFAULT admin_token ${ADMIN_TOKEN} 
	set_config /etc/keystone/keystone.conf DEFAULT verbose True
	
	set_config /etc/keystone/keystone.conf database connection mysql://keystone:${KEYSTONE_DBPASS}@controller/keystone

	set_config /etc/keystone/keystone.conf memcache servers localhost:11211

	set_config /etc/keystone/keystone.conf token provider keystone.token.providers.uuid.Provider
	set_config /etc/keystone/keystone.conf token driver keystone.token.persistence.backends.memcache.Token

	set_config /etc/keystone/keystone.conf revoke driver keystone.contrib.revoke.backends.sql.Revoke
}

db_sync_keystone() {
	su -s /bin/sh -c "keystone-manage db_sync" keystone
}

config_apache() {
	sed -i '1i ServerName controller' /etc/apache2/apache2.conf

	cat > /etc/apache2/sites-available/wsgi-keystone.conf <<EOF
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
EOF

	ln -s /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-enabled
	mkdir -p /var/www/cgi-bin/keystone

	curl http://git.openstack.org/cgit/openstack/keystone/plain/httpd/keystone.py?h=stable/kilo \
	| tee /var/www/cgi-bin/keystone/main /var/www/cgi-bin/keystone/admin

	chown -R keystone:keystone /var/www/cgi-bin/keystone
	chmod 755 /var/www/cgi-bin/keystone/*
}

restart_apache() {
	service apache2 restart
	rm -f /var/lib/keystone/keystone.db
}

create_db keystone keystone ${KEYSTONE_DBPASS}
install_keystone
config_keystone
db_sync_keystone
config_apache
restart_apache
