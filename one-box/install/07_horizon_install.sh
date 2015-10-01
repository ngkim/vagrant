#!/bin/bash

source "./00_check_config.sh"
source "$WORK_HOME/include/openstack/01_identity.sh"
source "$WORK_HOME/include/openstack/02_endpoint.sh"
source "$WORK_HOME/include/openstack/03_database.sh"

install_dashboard() {
	apt-get install -y openstack-dashboard
}

config_dashboard() {
	echo "+------------------------------------------------------------------------------"
	echo "DO IT MANUALLY!!! /etc/openstack-dashboard/local_settings.py"
	echo "+------------------------------------------------------------------------------"
	echo "OPENSTACK_HOST = ${BOXNAME}"
	echo ""
	echo "ALLOWED_HOSTS = '*'"
	echo ""
	echo "CACHES = {"
	echo "   'default': {"
	echo "       'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',"
	echo "       'LOCATION': '127.0.0.1:11211',"
	echo "   }"
	echo "}"
	echo ""
	echo "OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"user\""
	echo ""
	echo "TIME_ZONE = ${TIME_ZONE}"
	echo "+------------------------------------------------------------------------------"
	
	#Set default role
    HORIZON_CONF="/etc/openstack-dashboard/local_settings.py"
    sed -i "s/DEBUG = \"False\"/DEBUG = \"True\"/g" $HORIZON_CONF
    sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"${BOXNAME}\"/g" $HORIZON_CONF 
    sed -i "s/OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"_member_\"/OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"user\"/g" $HORIZON_CONF
    sed -i "s/TIME_ZONE = \"UTC\"/TIME_ZONE = \"${TIME_ZONE}\"/g" $HORIZON_CONF
}

restart_dashboard() {
	service apache2 reload
}

#==================================================================
print_title "HORIZON - INSTALL"
#==================================================================

install_dashboard
config_dashboard
restart_dashboard
