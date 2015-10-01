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

	set_config /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host ${BOXNAME}
	set_config /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid openstack
	set_config /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}
	
	#keystone_authtoken
	set_config /etc/neutron/neutron.conf keystone_authtoken auth_uri http://${BOXNAME}:5000
	set_config /etc/neutron/neutron.conf keystone_authtoken auth_url http://${BOXNAME}:35357
	set_config /etc/neutron/neutron.conf keystone_authtoken auth_plugin password
	set_config /etc/neutron/neutron.conf keystone_authtoken project_domain_id default
	set_config /etc/neutron/neutron.conf keystone_authtoken user_domain_id default
	set_config /etc/neutron/neutron.conf keystone_authtoken project_name service
	set_config /etc/neutron/neutron.conf keystone_authtoken username neutron
	set_config /etc/neutron/neutron.conf keystone_authtoken password ${NEUTRON_PASS}
}

config_neutron_ml2_sriov() {
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,sriovnicswitch

	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2_sriov supported_pci_vendor_devs ${PCI_VENDOR_DEV}
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2_sriov agent_required True

	set_config /etc/neutron/plugins/ml2/ml2_conf.ini sriov_nic physical_device_mappings ${SRIOV_NIC}
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini sriov_nic exclude_devices ""

}

config_neutron_ml2() {
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types flat,vlan
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch

	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks ${FLAT_NETWORKS}
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vlan network_vlan_ranges ${VLAN_RANGES}
	
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ovs integration_bridge br-int
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ovs bridge_mappings ${BRIDGE_MAPPINGS}

	#set_config /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.firewall.NoopFirewallDriver
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True

        if [ $NET_DRIVER == "sriov" ]; then 
            config_neutron_ml2_sriov
        fi
}

config_nova() {
	set_config /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
	set_config /etc/nova/nova.conf DEFAULT security_group_api neutron
	set_config /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
	set_config /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
	
	set_config /etc/nova/nova.conf neutron url http://${BOXNAME}:9696
	set_config /etc/nova/nova.conf neutron auth_strategy keystone
	set_config /etc/nova/nova.conf neutron admin_auth_url http://${BOXNAME}:35357/v2.0
	set_config /etc/nova/nova.conf neutron admin_tenant_name service
	set_config /etc/nova/nova.conf neutron admin_username neutron
	set_config /etc/nova/nova.conf neutron admin_password ${NEUTRON_PASS}
}

make_internal_bridge() {
  service openvswitch-switch restart

  for idx in ${!BRIDGE_LIST[@]}; do
    bridge=${BRIDGE_LIST[$idx]}
       
    ovs-vsctl add-br $bridge
  done	
}

restart_neutron() {
	service nova-compute restart
	service neutron-plugin-openvswitch-agent restart
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
config_nova
make_internal_bridge
restart_neutron

sleep 3
#==================================================================
print_title "NEUTRON NETWORK - VERIFY"
#==================================================================
print_msg "Perform these commands on the controller node."

source $OPENRC
neutron agent-list
