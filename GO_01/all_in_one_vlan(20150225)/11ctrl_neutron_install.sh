#! /bin/bash

ctrl_neutron_server_and_plugin_install() {

    echo '
    # ------------------------------------------------------------------------------
    ### ctrl_neutron_server_and_plugin_install() !!!
    # ------------------------------------------------------------------------------'

     
    echo '  neutron service 설치'
    apt-get -y install \
    	neutron-server
        
    echo '  neutron plugin 설치'    
    apt-get -y install \
    	neutron-common \
        neutron-plugin-ml2 
    
    echo '  neutron agent 설치'    
    apt-get -y install \
        neutron-plugin-openvswitch-agent \
        neutron-l3-agent \
        neutron-dhcp-agent
    
    echo '>>> check result'
    echo '# ------------------------------------------------------------------------------'        
    dpkg -l | grep neutron
    echo '# ------------------------------------------------------------------------------'
}

ctrl_neutron_db_create() {

    echo '
    # ------------------------------------------------------------------------------
    ### ctrl_neutron_db_create() !!!
    # ------------------------------------------------------------------------------'
    
    mysql -uroot -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE neutron;'
    mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$MYSQL_NEUTRON_PASS';"
    mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$MYSQL_NEUTRON_PASS';"
    
    echo '>>> check result -----------------------------------------------------'    
    mysql -u root -p${MYSQL_ROOT_PASS} -h localhost -e "show databases;"
    echo '# --------------------------------------------------------------------'    
}


ctrl_neutron_server_configure() {

    echo "
    # ------------------------------------------------------------------------------
    ### ctrl_neutron_server_configure(${NEUTRON_CONF}) !!!
    # ------------------------------------------------------------------------------"
    
    SERVICE_TENANT_ID=$(keystone tenant-list | grep ${SERVICE_TENANT} | awk '{print $2}')
    NEUTRON_USER_ID=$(keystone user-list | awk '/\ neutron \ / {print $2}')
    
    #List the new user and role assigment
    keystone user-list --tenant-id $SERVICE_TENANT_ID
    keystone user-role-list --tenant-id $SERVICE_TENANT_ID --user-id $NEUTRON_USER_ID

    echo '  4.3 neutron 서버 콤포넌트 구성(/etc/neutron/neutron.conf)'

    backup_org ${NEUTRON_CONF}
    
#Configure Neutron
cat > ${NEUTRON_CONF} << EOF
# ------------------------------------------------------------------------------
[DEFAULT]
verbose = True
debug = True
state_path = /var/lib/neutron
lock_path = \$state_path/lock
log_dir = /var/log/neutron

bind_host = 0.0.0.0
bind_port = 9696

#Plugin
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = True

#auth
auth_strategy = keystone

#RPC configuration options. Defined in rpc __init__
#The messaging module to use, defaults to kombu.
rpc_backend = neutron.openstack.common.rpc.impl_kombu

rabbit_host = ${CTRL_HOST}
rabbit_password = guest
rabbit_port = 5672
rabbit_userid = guest
rabbit_virtual_host = /
rabbit_ha_queues = false

#============ Notification System Options =====================
notification_driver = neutron.openstack.common.notifier.rpc_notifier

#======== neutron nova interactions ==========
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True
nova_url = http://${CTRL_HOST}:8774/v2
nova_region_name = regionOne
nova_admin_username = $NOVA_SERVICE_USER
nova_admin_tenant_id = $SERVICE_TENANT_ID
nova_admin_password = $NOVA_SERVICE_PASS
nova_admin_auth_url = http://${CTRL_HOST}:35357/v2.0

[quotas]
# resource name(s) that are supported in quota features
quota_items = network,subnet,port
 
# number of networks allowed per tenant, and minus means unlimited
quota_network = 10
 
# number of subnets allowed per tenant, and minus means unlimited
quota_subnet = 10
 
# number of ports allowed per tenant, and minus means unlimited
quota_port = 50
 
# default driver to use for quota checks
quota_driver = neutron.quota.ConfDriver

# number of routers allowed per tenant, and minus means unlimited
quota_router = 10
 
# number of floating IPs allowed per tenant, and minus means unlimited
quota_floatingip = 50

# number of security groups per tenant, and minus means unlimited
quota_security_group = 10
 
# number of security rules allowed per tenant, and minus means unlimited
quota_security_group_rule = 100

[agent]
root_helper = sudo

[keystone_authtoken]
auth_host = ${CTRL_HOST}
auth_port = 35357
auth_protocol = http
admin_tenant_name = ${SERVICE_TENANT}
admin_user = ${NEUTRON_SERVICE_USER}
admin_password = ${NEUTRON_SERVICE_PASS}
signing_dir = \$state_path/keystone-signing

[database]
connection = mysql://neutron:${MYSQL_NEUTRON_PASS}@${CTRL_HOST}/neutron

[service_providers]
#service_provider=LOADBALANCER:Haproxy:neutron.services.loadbalancer.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default
#service_provider=VPN:openswan:neutron.services.vpn.service_drivers.ipsec.IPsecVPNDriver:default
# ------------------------------------------------------------------------------
EOF
    
    echo '>>> check result -----------------------------------------------------'    
    cat $NEUTRON_CONF
    echo '# --------------------------------------------------------------------'

}

ctrl_neutron_plugin_ml2_configure() {

    echo "
    # ------------------------------------------------------------------------------
    ### ctrl_neutron_plugin_ml2_configure(${NEUTRON_PLUGIN_ML2_CONF_INI}) !!!
    # ------------------------------------------------------------------------------"
    
    backup_org ${NEUTRON_PLUGIN_ML2_CONF_INI}
    
#LJG: 설정은 하고 있으나 실질적으로 controller node에서는 mgmt/api network만 사용하므로 불필요
cat > ${NEUTRON_PLUGIN_ML2_CONF_INI} << EOF
# ------------------------------------------------------------------------------
[ml2]
type_drivers = vlan
tenant_network_types = vlan
mechanism_drivers = openvswitch

[ml2_type_vlan]
# ex) network_vlan_ranges = physnet_guest:2001:4000,physnet_lan:1:2000,physnet_wan:1:2000
network_vlan_ranges = ${PHY_GUEST_NET_RANGE},${PHY_LAN_NET_RANGE},${PHY_WAN_NET_RANGE}

[ovs]
integration_bridge = ${LOG_INT_BR}
# guest/lan/wan network 만 매핑
# ex) bridge_mappings = physnet_guest:br-guest,physnet_lan:br-lan,physnet_wan:br-wan,physnet_ext:br-ext
bridge_mappings = ${PHY_GUEST_NET}:${LOG_GUEST_BR},${PHY_LAN_NET}:${LOG_LAN_BR},${PHY_WAN_NET}:${LOG_WAN_BR},${PHY_EXT_NET}:${LOG_EXT_BR}


#[ml2]
#type_drivers = gre
#tenant_network_types = gre
#mechanism_drivers = openvswitch

#[ml2_type_gre]
#tunnel_id_ranges = 1:1000

#[ovs]
#local_ip = ${CTRL_HOST}
#tunnel_type = gre
#enable_tunneling = True

[securitygroup]
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
enable_security_group = True
# ------------------------------------------------------------------------------
EOF
    echo '>>> check result -----------------------------------------------------'    
    cat $NEUTRON_PLUGIN_ML2_CONF_INI
    echo '# --------------------------------------------------------------------'

}

ctrl_neutron_l3_agent_config() {
    echo "
    # --------------------------------------------------------------------------
    ### ctrl_neutron_l3_agent_config<$NEUTRON_L3_AGENT_INI>_config !!!
    # --------------------------------------------------------------------------"

    backup_org $NEUTRON_L3_AGENT_INI
    
cat > ${NEUTRON_L3_AGENT_INI} << EOF
# ------------------------------------------------------------------------------
[DEFAULT]
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
use_namespaces = True
EOF

    echo '>>> check result'
    echo '# ------------------------------------------------------------------------------'
    cat $NEUTRON_L3_AGENT_INI
    echo '# ------------------------------------------------------------------------------'

}

ctrl_neutron_dhcp_agent_config() {

    echo "
    # --------------------------------------------------------------------------
    ### ctrl_neutron_dhcp_agent_config<$NEUTRON_DHCP_AGENT_INI>_config !!!
    # --------------------------------------------------------------------------"
    
    backup_org $NEUTRON_DHCP_AGENT_INI
    
cat > ${NEUTRON_DHCP_AGENT_INI} << EOF
[DEFAULT]
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
use_namespaces = True
EOF

    echo '>>> check result'
    echo '# ------------------------------------------------------------------------------'
    cat $NEUTRON_DHCP_AGENT_INI
    echo '# ------------------------------------------------------------------------------'
}

ctrl_neutron_metadata_agent_config() {

    echo "
    # --------------------------------------------------------------------------
    ### ctrl_neutron_metadata_agent_config<$NEUTRON_METADATA_AGENT_INI>_config !!!
    # --------------------------------------------------------------------------"
    backup_org $NEUTRON_METADATA_AGENT_INI
        
cat > ${NEUTRON_METADATA_AGENT_INI} << EOF
[DEFAULT]
auth_url = http://${CTRL_HOST}:5000/v2.0
auth_region = regionOne
admin_tenant_name = service
admin_user = ${NEUTRON_SERVICE_USER}
admin_password = ${NEUTRON_SERVICE_PASS}
nova_metadata_ip = ${CTRL_HOST}
metadata_proxy_shared_secret = foo
# ------------------------------------------------------------------------------
EOF
    
    echo '>>> check result'
    echo '# ------------------------------------------------------------------------------'
    cat $NEUTRON_METADATA_AGENT_INI
    echo '# ------------------------------------------------------------------------------'
    
}

ctrl_neutron_sudoers_append() {
    echo '
    # ------------------------------------------------------------------------------
    ### neutron_neutron_sudoers_append(/etc/sudoers) !!!
    # ------------------------------------------------------------------------------'

echo "
Defaults !requiretty
neutron ALL=(ALL:ALL) NOPASSWD:ALL" | tee -a /etc/sudoers

    echo '>>> check result -----------------------------------------------------'
    cat /etc/sudoers
    echo '# --------------------------------------------------------------------'

}

ctrl_neutron_server_restart() {
    echo '
    # ------------------------------------------------------------------------------
    ### ctrl_neutron_server_restart() !!!
    # ------------------------------------------------------------------------------'
    
    for process in $(ls /etc/init/neutron* | cut -d'/' -f4 | cut -d'.' -f1);do service ${process} restart;	done
	    
    echo '>>> check result -----------------------------------------------------'
    ps -ef | grep neutron
    echo '# --------------------------------------------------------------------'
}