#!/bin/bash

source "./00_check_config.sh"
source "$WORK_HOME/include/openstack/01_identity.sh"
source "$WORK_HOME/include/openstack/02_endpoint.sh"
source "$WORK_HOME/include/openstack/03_database.sh"

install_ceilometer_agent() {
	apt-get install -y ceilometer-agent-compute
}

config_ceilometer_agent() {
	local CFG_FILE="/etc/ceilometer/ceilometer.conf"
	
	set_config ${CFG_FILE} publisher telemetry_secret ${TELEMETRY_SECRET}
	
	set_config ${CFG_FILE} DEFAULT rpc_backend rabbit
 
	set_config ${CFG_FILE} oslo_messaging_rabbit rabbit_host controller
	set_config ${CFG_FILE} oslo_messaging_rabbit rabbit_userid openstack
	set_config ${CFG_FILE} oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}
	
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
	
	set_config ${CFG_FILE} DEFAULT verbose True	
}

config_nova_for_ceilometer_agent() {
	local CFG_FILE="/etc/nova/nova.conf"
		
	set_config ${CFG_FILE} DEFAULT instance_usage_audit True
	set_config ${CFG_FILE} DEFAULT instance_usage_audit_period hour
	set_config ${CFG_FILE} DEFAULT notify_on_state_change vm_and_task_state
	set_config ${CFG_FILE} DEFAULT notification_driver messagingv2	
}

restart_ceilometer_agent() {
	service ceilometer-agent-compute restart
}

restart_nova_compute() {
	service nova-compute restart	
}

#==================================================================
print_title "CEILOMETER COMPUTE AGENT - INSTALL"
#==================================================================

install_ceilometer_agent
config_ceilometer_agent
config_nova_for_ceilometer_agent
restart_ceilometer_agent
restart_nova_compute
