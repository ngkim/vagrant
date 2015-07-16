#!/bin/bash

source "/vagrant/config/default.cfg"
source "/vagrant/include/print_util.sh"
source "/vagrant/include/12_config.sh"
source "/vagrant/include/openstack/01_identity.sh"
source "/vagrant/include/openstack/02_endpoint.sh"
source "/vagrant/include/openstack/03_database.sh"

install_heat() {
	apt-get install -y heat-api heat-api-cfn heat-engine python-heatclient
}

config_heat() {
	local CFG_FILE="/etc/heat/heat.conf"
	
	set_config $CFG_FILE database connection mysql://heat:${HEAT_DBPASS}@controller/heat
	
	set_config $CFG_FILE DEFAULT rpc_backend rabbit
	set_config $CFG_FILE oslo_messaging_rabbit rabbit_host controller
	set_config $CFG_FILE oslo_messaging_rabbit rabbit_userid openstack
	set_config $CFG_FILE oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}
		
	set_config $CFG_FILE keystone_authtoken auth_uri http://controller:5000/v2.0
	set_config $CFG_FILE keystone_authtoken identity_uri http://controller:35357
	set_config $CFG_FILE keystone_authtoken admin_tenant_name service
	set_config $CFG_FILE keystone_authtoken admin_user heat
	set_config $CFG_FILE keystone_authtoken admin_password ${HEAT_PASS}
	
	set_config $CFG_FILE ec2authtoken auth_uri = http://controller:5000/v2.0
	
	set_config $CFG_FILE DEFAULT heat_metadata_server_url http://controller:8000
	set_config $CFG_FILE DEFAULT heat_waitcondition_server_url http://controller:8000/v1/waitcondition
	
	set_config $CFG_FILE DEFAULT stack_domain_admin heat_domain_admin
	set_config $CFG_FILE DEFAULT stack_domain_admin_password ${HEAT_DOMAIN_PASS}
	set_config $CFG_FILE DEFAULT stack_user_domain_name heat_user_domain
	
	set_config $CFG_FILE DEFAULT verbose True
}
	
create_heat_domain() {	
	heat-keystone-setup-domain \
	--stack-user-domain-name heat_user_domain \
	--stack-domain-admin heat_domain_admin \
	--stack-domain-admin-password ${HEAT_DOMAIN_PASS}
}

db_sync_heat() {
	su -s /bin/sh -c "heat-manage db_sync" heat
}

restart_heat() {
	service heat-api restart
	service heat-api-cfn restart
	service heat-engine restart

	rm -f /var/lib/heat/heat.sqlite
}

#==================================================================
print_title "HEAT - PREPARE"
#==================================================================

source $OPENRC

create_db heat heat ${HEAT_DBPASS}

create_user heat ${HEAT_PASS}
add_user_to_role heat service admin
create_role heat_stack_owner
add_user_to_role demo demo heat_stack_owner
create_role heat_stack_user

create_heat_service
create_heat_cfn_service
create_heat_orchestration_endpoint
create_heat_cfn_endpoint

#==================================================================
print_title "HEAT - INSTALL"
#==================================================================

install_heat
config_heat
create_heat_domain
db_sync_heat
restart_heat
