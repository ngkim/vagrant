#!/bin/bash

source "../config/default.cfg"
source "../include/print_util.sh"
source "../include/12_config.sh"
source "../include/openstack/01_identity.sh"
source "../include/openstack/02_endpoint.sh"
source "../include/openstack/03_database.sh"

config_glance_api() {
	local CFG_FILE="/etc/glance/glance-api.conf"
	
	set_config ${CFG_FILE} DEFAULT notification_driver messagingv2
	set_config ${CFG_FILE} DEFAULT rpc_backend rabbit
	set_config ${CFG_FILE} DEFAULT rabbit_host controller
	set_config ${CFG_FILE} DEFAULT rabbit_userid openstack
	set_config ${CFG_FILE} DEFAULT rabbit_password ${RABBIT_PASS}
}

config_glance_registry() {
	local CFG_FILE="/etc/glance/glance-registry.conf"
	
	set_config ${CFG_FILE} DEFAULT notification_driver messagingv2
	set_config ${CFG_FILE} DEFAULT rpc_backend rabbit
	set_config ${CFG_FILE} DEFAULT rabbit_host controller
	set_config ${CFG_FILE} DEFAULT rabbit_userid openstack
	set_config ${CFG_FILE} DEFAULT rabbit_password ${RABBIT_PASS}
}

restart_glance_for_ceilometer() {
	service glance-registry restart
	service glance-api restart
}

#==================================================================
print_title "CEILOMETER for IMAGE SERVICE - CONFIG"
#==================================================================

config_glance_api
config_glance_registry
restart_glance_for_ceilometer