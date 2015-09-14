#!/bin/bash

source "./00_check_config.sh"
source "$WORK_HOME/include/openstack/01_identity.sh"
source "$WORK_HOME/include/openstack/02_endpoint.sh"
source "$WORK_HOME/include/openstack/03_database.sh"

config_sysctl() {
	cat >> /etc/sysctl.conf <<EOF
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
EOF

	sysctl -p
}
	
install_neutron() {
	apt-get install -y neutron-plugin-ml2 neutron-plugin-openvswitch-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent
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
}

config_neutron_ml2() {
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers vlan
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vlan	
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch

	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vlan network_vlan_ranges ${VLAN_RANGES}
	
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ovs integration_bridge br-int
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ovs bridge_mappings ${BRIDGE_MAPPINGS}

	set_config /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
}

config_neutron_l3_agent() {
	set_config /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
	set_config /etc/neutron/l3_agent.ini DEFAULT router_delete_namespaces True
	set_config /etc/neutron/l3_agent.ini DEFAULT verbose True
}

config_neutron_dhcp_agent() {
	set_config /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
	set_config /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
	set_config /etc/neutron/dhcp_agent.ini DEFAULT dhcp_delete_namespaces True
	set_config /etc/neutron/dhcp_agent.ini DEFAULT verbose True	
}

config_neutron_metadata_agent() {
	set_config /etc/neutron/metadata_agent.ini DEFAULT auth_uri http://controller:5000
	set_config /etc/neutron/metadata_agent.ini DEFAULT auth_url http://controller:35357
	set_config /etc/neutron/metadata_agent.ini DEFAULT auth_region ${REGION_NAME}
	set_config /etc/neutron/metadata_agent.ini DEFAULT auth_plugin password
	set_config /etc/neutron/metadata_agent.ini DEFAULT project_domain_id default
	set_config /etc/neutron/metadata_agent.ini DEFAULT user_domain_id default
	set_config /etc/neutron/metadata_agent.ini DEFAULT project_name service
	set_config /etc/neutron/metadata_agent.ini DEFAULT username neutron
	set_config /etc/neutron/metadata_agent.ini DEFAULT password ${NEUTRON_PASS}
	
	set_config /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip ${CTRL_MGMT_IP}
	set_config /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret ${METADATA_SECRET}
	set_config /etc/neutron/metadata_agent.ini DEFAULT verbose True
}

make_ext_bridge() {
	service openvswitch-switch restart
	ovs-vsctl add-br br-ex
	ovs-vsctl add-port br-ex ${EXT_NIC}
}

restart_neutron() {	
	service neutron-plugin-openvswitch-agent restart
	service neutron-l3-agent restart
	service neutron-dhcp-agent restart
	service neutron-metadata-agent restart
}

#==================================================================
print_title "NEUTRON NETWORK - PREPARE"
#==================================================================

config_sysctl

#==================================================================
print_title "NEUTRON NETWORK - INSTALL"
#==================================================================

install_neutron
config_neutron
config_neutron_ml2
config_neutron_l3_agent
config_neutron_dhcp_agent
config_neutron_metadata_agent
make_ext_bridge
restart_neutron

#==================================================================
print_title "NEUTRON NETWORK - VERIFY"
#==================================================================
print_msg "Perform these commands on the controller node."

source $OPENRC
neutron agent-list
