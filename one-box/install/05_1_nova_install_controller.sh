#!/bin/bash

source "./00_check_config.sh"
source "$WORK_HOME/include/openstack/01_identity.sh"
source "$WORK_HOME/include/openstack/02_endpoint.sh"
source "$WORK_HOME/include/openstack/03_database.sh"

install_nova() {
	apt-get install -y nova-api nova-cert nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient	
}

config_nova() {
	set_config /etc/nova/nova.conf DEFAULT rpc_backend rabbit
	set_config /etc/nova/nova.conf DEFAULT verbose True
	set_config /etc/nova/nova.conf DEFAULT use_syslog True
	set_config /etc/nova/nova.conf DEFAULT syslog_log_facility LOG_LOCAL0
	set_config /etc/nova/nova.conf DEFAULT auth_strategy keystone
	
	set_config /etc/nova/nova.conf DEFAULT my_ip ${CTRL_MGMT_IP}

	set_config /etc/nova/nova.conf DEFAULT vnc_enabled True
	set_config /etc/nova/nova.conf DEFAULT vncserver_listen 0.0.0.0
	set_config /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address ${CTRL_MGMT_IP}
	set_config /etc/nova/nova.conf DEFAULT novncproxy_base_url http://${PUBLIC_IP}:6080/vnc_auto.html

	set_config /etc/nova/nova.conf DEFAULT vif_plugging_is_fatal False
	set_config /etc/nova/nova.conf DEFAULT vif_plugging_timeout 0
	
	set_config /etc/nova/nova.conf database connection mysql://nova:${NOVA_DBPASS}@${BOXNAME}/nova
	
	set_config /etc/nova/nova.conf glance host ${BOXNAME}

	set_config /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

	set_config /etc/nova/nova.conf oslo_messaging_rabbit rabbit_host ${BOXNAME}
	set_config /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid openstack
	set_config /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

	set_config /etc/nova/nova.conf keystone_authtoken auth_uri http://${BOXNAME}:5000
	set_config /etc/nova/nova.conf keystone_authtoken auth_url http://${BOXNAME}:35357
	set_config /etc/nova/nova.conf keystone_authtoken auth_plugin password
	set_config /etc/nova/nova.conf keystone_authtoken project_domain_id default
	set_config /etc/nova/nova.conf keystone_authtoken user_domain_id default
	set_config /etc/nova/nova.conf keystone_authtoken project_name service
	set_config /etc/nova/nova.conf keystone_authtoken username nova
	set_config /etc/nova/nova.conf keystone_authtoken password ${NOVA_PASS}
}

db_sync_nova() {
	su -s /bin/sh -c "nova-manage db sync" nova
}

restart_nova() {
	service nova-api restart
	service nova-cert restart
	service nova-consoleauth restart
	service nova-scheduler restart
	service nova-conductor restart
	service nova-novncproxy restart
		
	rm -f /var/lib/nova/nova.sqlite
}

#==================================================================
print_title "NOVA - PREPARE"
#==================================================================

prepare() {
	source $OPENRC

	create_db nova nova ${NOVA_DBPASS}

	create_user nova ${NOVA_PASS}
	add_user_to_role nova service admin

	create_nova_service
	create_nova_endpoint
}

prepare

#==================================================================
print_title "NOVA - INSTALL"
#==================================================================

install() {
	install_nova
	config_nova
	db_sync_nova
	restart_nova
}

install


