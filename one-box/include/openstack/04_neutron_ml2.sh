config_ml2_ovs_clear() {
	clear_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers
	clear_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types
	clear_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers

	clear_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks
	clear_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vlan network_vlan_ranges
	clear
	clear_config /etc/neutron/plugins/ml2/ml2_conf.ini ovs integration_bridge
	clear_config /etc/neutron/plugins/ml2/ml2_conf.ini ovs bridge_mappings

	clear_config /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver
	clear_config /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group
	clear_config /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset
}

config_ml2_ovs() {
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types flat,vlan
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch

	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks ${FLAT_NETWORKS}
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vlan network_vlan_ranges ${VLAN_RANGES}

	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ovs integration_bridge br-int
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini ovs bridge_mappings ${BRIDGE_MAPPINGS}

	set_config /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.firewall.NoopFirewallDriver
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
	set_config /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
}

config_ml2_sriov_clear() {
        clear_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers

        clear_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2_sriov supported_pci_vendor_devs
        clear_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2_sriov agent_required

        clear_config /etc/neutron/plugins/ml2/ml2_conf.ini sriov_nic physical_device_mappings
        clear_config /etc/neutron/plugins/ml2/ml2_conf.ini sriov_nic exclude_devices

}

config_ml2_sriov() {
        set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,sriovnicswitch

        set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2_sriov supported_pci_vendor_devs ${PCI_VENDOR_DEV}
        set_config /etc/neutron/plugins/ml2/ml2_conf.ini ml2_sriov agent_required True

        set_config /etc/neutron/plugins/ml2/ml2_conf.ini sriov_nic physical_device_mappings ${SRIOV_NIC}
        set_config /etc/neutron/plugins/ml2/ml2_conf.ini sriov_nic exclude_devices ""

}

make_internal_bridge() {
  service openvswitch-switch restart

  for idx in ${!BRIDGE_LIST[@]}; do
    bridge=${BRIDGE_LIST[$idx]}
       
    ovs-vsctl add-br $bridge
  done	
}

restart_neutron() {
        service nova-api restart
        service neutron-server restart
}

