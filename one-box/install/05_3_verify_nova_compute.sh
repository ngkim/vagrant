#!/bin/bash

source "./00_check_config.sh"
source "$WORK_HOME/include/print_util.sh"
source "$WORK_HOME/include/openstack/01_identity.sh"
source "$WORK_HOME/include/openstack/02_endpoint.sh"
source "$WORK_HOME/include/openstack/03_database.sh"

install_nova_compute() {	
	apt-get install -y nova-compute sysfsutils
}

config_nova() {
	set_config /etc/nova/nova.conf DEFAULT rpc_backend rabbit
	set_config /etc/nova/nova.conf DEFAULT verbose True
	set_config /etc/nova/nova.conf DEFAULT auth_strategy keystone
	set_config /etc/nova/nova.conf DEFAULT my_ip ${COMP_MGMT_IP}

	set_config /etc/nova/nova.conf DEFAULT vnc_enabled True
	set_config /etc/nova/nova.conf DEFAULT vncserver_listen 0.0.0.0
	set_config /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address ${COMP_MGMT_IP}
	set_config /etc/nova/nova.conf DEFAULT novncproxy_base_url http://controller:6080/vnc_auto.html
	
	set_config /etc/nova/nova.conf database connection mysql://nova:${NOVA_DBPASS}@controller/nova

	set_config /etc/nova/nova.conf glance host controller

	set_config /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

	set_config /etc/nova/nova.conf oslo_messaging_rabbit rabbit_host controller
	set_config /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid openstack
	set_config /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

	set_config /etc/nova/nova.conf keystone_authtoken auth_uri http://controller:5000
	set_config /etc/nova/nova.conf keystone_authtoken auth_url http://controller:35357
	set_config /etc/nova/nova.conf keystone_authtoken auth_plugin password
	set_config /etc/nova/nova.conf keystone_authtoken project_domain_id default
	set_config /etc/nova/nova.conf keystone_authtoken user_domain_id default
	set_config /etc/nova/nova.conf keystone_authtoken project_name service
	set_config /etc/nova/nova.conf keystone_authtoken username nova
	set_config /etc/nova/nova.conf keystone_authtoken password ${NOVA_PASS}
}

config_nova_compute() {
	set_config /etc/nova/nova-compute.conf libvirt virt_type ${VIRT_TYPE}	
}

restart_nova_compute() {
	service nova-compute restart
	rm -f /var/lib/nova/nova.sqlite
}

#==================================================================
print_title "NOVA COMPUTE - VERIFY"
#==================================================================

source $OPENRC

cmd="nova service-list"
run_commands $cmd

cmd="nova endpoints"
run_commands $cmd

cmd="nova image-list"
run_commands $cmd
