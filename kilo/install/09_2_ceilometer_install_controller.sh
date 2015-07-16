#!/bin/bash

source "../config/default.cfg"
source "../include/print_util.sh"
source "../include/12_config.sh"
source "../include/openstack/01_identity.sh"
source "../include/openstack/02_endpoint.sh"
source "../include/openstack/03_database.sh"

install_ceilometer() {
	apt-get install -y ceilometer-api ceilometer-collector ceilometer-agent-central \
		ceilometer-agent-notification ceilometer-alarm-evaluator ceilometer-alarm-notifier \
		python-ceilometerclient	
}

config_ceilometer() {
	local CFG_FILE="/etc/ceilometer/ceilometer.conf"
	
	set_config ${CFG_FILE} database connection mongodb://ceilometer:${CEILOMETER_DBPASS}@controller:27017/ceilometer
	
	set_config ${CFG_FILE} DEFAULT rpc_backend rabbit
 
	set_config ${CFG_FILE} oslo_messaging_rabbit rabbit_host controller
	set_config ${CFG_FILE} oslo_messaging_rabbit rabbit_userid openstack
	set_config ${CFG_FILE} oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}
	
	set_config ${CFG_FILE} DEFAULT auth_strategy keystone
 
	set_config ${CFG_FILE} keystone_authtoken auth_uri http://controller:5000/v2.0
	set_config ${CFG_FILE} keystone_authtoken identity_uri http://controller:35357
	set_config ${CFG_FILE} keystone_authtoken admin_tenant_name service
	set_config ${CFG_FILE} keystone_authtoken admin_user ceilometer
	set_config ${CFG_FILE} keystone_authtoken admin_password ${CEILOMETER_PASS}
	
	set_config ${CFG_FILE} service_credentials os_auth_url http://controller:5000/v2.0
	set_config ${CFG_FILE} service_credentials os_username ceilometer
	set_config ${CFG_FILE} service_credentials os_tenant_name service
	set_config ${CFG_FILE} service_credentials os_password ${CEILOMETER_PASS}
	set_config ${CFG_FILE} service_credentials os_endpoint_type internalURL
	set_config ${CFG_FILE} service_credentials os_region_name ${REGION_NAME}
	
	set_config ${CFG_FILE} publisher telemetry_secret ${TELEMETRY_SECRET}
	
	set_config ${CFG_FILE} DEFAULT verbose True	
}

restart_ceilometer() {
	service ceilometer-agent-central restart
	service ceilometer-agent-notification restart
	service ceilometer-api restart
	service ceilometer-collector restart
	service ceilometer-alarm-evaluator restart
	service ceilometer-alarm-notifier restart
}

#==================================================================
print_title "CEILOMETER - PREPARE"
#==================================================================

source $OPENRC

create_user ceilometer ${CEILOMETER_PASS}
add_user_to_role ceilometer service admin

create_ceilometer_service
create_ceilometer_endpoint

#==================================================================
print_title "CEILOMETER - INSTALL"
#==================================================================

install_ceilometer
config_ceilometer
restart_ceilometer
