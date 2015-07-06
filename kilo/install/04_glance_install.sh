#!/bin/bash

source "/vagrant/config/default.cfg"
source "/vagrant/include/print_util.sh"
source "/vagrant/include/12_config.sh"
source "/vagrant/include/openstack/01_identity.sh"
source "/vagrant/include/openstack/02_endpoint.sh"
source "/vagrant/include/openstack/03_database.sh"

install_glance() {
	apt-get install -y glance python-glanceclient
}

config_glance_api() {
	set_config /etc/glance/glance-api.conf DEFAULT notification_driver noop 
	set_config /etc/glance/glance-api.conf DEFAULT verbose True
	
	set_config /etc/glance/glance-api.conf database connection mysql://glance:${GLANCE_DBPASS}@controller/glance
	
	set_config /etc/glance/glance-api.conf keystone_authtoken auth_uri http://controller:5000
	set_config /etc/glance/glance-api.conf keystone_authtoken auth_url http://controller:35357
	set_config /etc/glance/glance-api.conf keystone_authtoken auth_plugin password
	set_config /etc/glance/glance-api.conf keystone_authtoken project_domain_id default
	set_config /etc/glance/glance-api.conf keystone_authtoken user_domain_id default
	set_config /etc/glance/glance-api.conf keystone_authtoken project_name service
	set_config /etc/glance/glance-api.conf keystone_authtoken username glance
	set_config /etc/glance/glance-api.conf keystone_authtoken password ${GLANCE_PASS}
	
	set_config /etc/glance/glance-api.conf paste_deploy flavor keystone
	
	set_config /etc/glance/glance-api.conf glance_store default_store file
	set_config /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/
}

config_glance_registry() {
	set_config /etc/glance/glance-registry.conf DEFAULT notification_driver noop
	set_config /etc/glance/glance-registry.conf DEFAULT verbose True
	
	set_config /etc/glance/glance-registry.conf database connection mysql://glance:${GLANCE_DBPASS}@controller/glance
	
	set_config /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://controller:5000
	set_config /etc/glance/glance-registry.conf keystone_authtoken auth_url http://controller:35357
	set_config /etc/glance/glance-registry.conf keystone_authtoken auth_plugin password
	set_config /etc/glance/glance-registry.conf keystone_authtoken project_domain_id default
	set_config /etc/glance/glance-registry.conf keystone_authtoken user_domain_id default
	set_config /etc/glance/glance-registry.conf keystone_authtoken project_name service
	set_config /etc/glance/glance-registry.conf keystone_authtoken username glance
	set_config /etc/glance/glance-registry.conf keystone_authtoken password ${GLANCE_PASS}
	
	set_config /etc/glance/glance-registry.conf paste_deploy flavor keystone
}
	
db_sync_glance() {
	su -s /bin/sh -c "glance-manage db_sync" glance
}

restart_glance() {
	service glance-registry restart
	service glance-api restart
	rm -f /var/lib/glance/glance.sqlite
}

#==================================================================
print_title "GLANCE - PREPARE"
#==================================================================

source $OPENRC

create_db glance glance ${GLANCE_DBPASS}

create_user glance ${GLANCE_PASS}
add_user_to_role glance service admin
create_glance_service
create_glance_endpoint

#==================================================================
print_title "GLANCE - INSTALL"
#==================================================================

install_glance
config_glance_api
config_glance_registry
db_sync_glance
restart_glance
