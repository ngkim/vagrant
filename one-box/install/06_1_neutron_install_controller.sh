#!/bin/bash

source "./00_check_config.sh"
source "$WORK_HOME/include/openstack/01_identity.sh"
source "$WORK_HOME/include/openstack/02_endpoint.sh"
source "$WORK_HOME/include/openstack/03_database.sh"

install_neutron() {
	apt-get install -y neutron-server neutron-plugin-ml2 python-neutronclient	
}

config_neutron() {
	set_config /etc/neutron/neutron.conf DEFAULT verbose True
	set_config /etc/neutron/neutron.conf DEFAULT use_syslog True
	set_config /etc/neutron/neutron.conf DEFAULT syslog_log_facility LOG_LOCAL4
	set_config /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
	set_config /etc/neutron/neutron.conf DEFAULT auth_strategy keystone

	set_config /etc/neutron/neutron.conf DEFAULT core_plugin ml2
	set_config /etc/neutron/neutron.conf DEFAULT service_plugins router
	set_config /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True

	set_config /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
	set_config /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
	set_config /etc/neutron/neutron.conf DEFAULT nova_url http://controller:8774/v2
	
	set_config /etc/neutron/neutron.conf database connection mysql://neutron:${NEUTRON_DBPASS}@controller/neutron

	set_config /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host controller
	set_config /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid openstack
	set_config /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

	#keystone_authtoken
	set_config /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller:5000
	set_config /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:35357
	set_config /etc/neutron/neutron.conf keystone_authtoken auth_plugin password
	set_config /etc/neutron/neutron.conf keystone_authtoken project_domain_id default
	set_config /etc/neutron/neutron.conf keystone_authtoken user_domain_id default
	set_config /etc/neutron/neutron.conf keystone_authtoken project_name service
	set_config /etc/neutron/neutron.conf keystone_authtoken username neutron
	set_config /etc/neutron/neutron.conf keystone_authtoken password ${NEUTRON_PASS}

	#nova
	set_config /etc/neutron/neutron.conf nova auth_url http://controller:35357
	set_config /etc/neutron/neutron.conf nova auth_plugin password
	set_config /etc/neutron/neutron.conf nova project_domain_id default
	set_config /etc/neutron/neutron.conf nova user_domain_id default
	set_config /etc/neutron/neutron.conf nova region_name ${REGION_NAME}
	set_config /etc/neutron/neutron.conf nova project_name service
	set_config /etc/neutron/neutron.conf nova username nova
	set_config /etc/neutron/neutron.conf nova password ${NOVA_PASS}	
}

config_neutron_ml2() {
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers vlan
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vlan	
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch

	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vlan network_vlan_ranges ${VLAN_RANGES}
	
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ovs integration_bridge br-int
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ovs bridge_mappings ${BRIDGE_MAPPINGS}

	#set_config /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.firewall.NoopFirewallDriver
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
}

config_nova() {
	set_config /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
	set_config /etc/nova/nova.conf DEFAULT security_group_api neutron
	set_config /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
	set_config /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
	
	set_config /etc/nova/nova.conf neutron url http://controller:9696
	set_config /etc/nova/nova.conf neutron auth_strategy keystone
	set_config /etc/nova/nova.conf neutron admin_auth_url http://controller:35357/v2.0
	set_config /etc/nova/nova.conf neutron admin_tenant_name service
	set_config /etc/nova/nova.conf neutron admin_username neutron
	set_config /etc/nova/nova.conf neutron admin_password ${NEUTRON_PASS}
	
	set_config /etc/nova/nova.conf neutron service_metadata_proxy True
	set_config /etc/nova/nova.conf neutron metadata_proxy_shared_secret ${METADATA_SECRET}
}

db_sync_neutron() {
	su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  		--config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
}

restart_neutron() {
	service nova-api restart
	service neutron-server restart
		
	rm -f /var/lib/nova/nova.sqlite
}

#==================================================================
print_title "NEUTRON - PREPARE"
#==================================================================

source $OPENRC

create_db neutron neutron ${NEUTRON_DBPASS}

create_user neutron ${NEUTRON_PASS}
add_user_to_role neutron service admin

create_neutron_service
create_neutron_endpoint

#==================================================================
print_title "NEUTRON - INSTALL"
#==================================================================

install_neutron
config_neutron
config_neutron_ml2
config_nova
sleep 3
db_sync_neutron
restart_neutron

#==================================================================
print_title "NEUTRON - VERIFY"
#==================================================================

source $OPENRC
neutron ext-list
