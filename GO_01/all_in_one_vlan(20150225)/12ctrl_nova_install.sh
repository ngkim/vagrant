#! /bin/bash

ctrl_nova_install() {

    echo '
    # ------------------------------------------------------------------------------
    ### ctrl_nova_install!!!
    # ------------------------------------------------------------------------------'

    echo '  5.1 nova service 설치'
    apt-get -y install \
        rabbitmq-server \
        dnsmasq \
        nova-novncproxy \
        nova-api \
        nova-cert \
        nova-conductor \
        nova-consoleauth \
        nova-doc \
        nova-scheduler \
        python-novaclient

    echo "nova sqlite db(/var/lib/nova/nova.sqlite) delete !!!"
    if [ -f /var/lib/nova/nova.sqlite ]; then
        rm /var/lib/nova/nova.sqlite        
    fi  
        

    echo '>>> check result------------------------------------------------------'
    dpkg -l | grep "nova"
    echo '# --------------------------------------------------------------------'

}

compute_nova_install() {

    echo '
    # ------------------------------------------------------------------------------
    ### compute_nova_install() !!!
    # ------------------------------------------------------------------------------'

    apt-get -y install nova-compute-kvm

    echo '>>> check result------------------------------------------------------'
    dpkg -l | egrep "nova-compute-kvm"
    echo '# --------------------------------------------------------------------'

}

ctrl_nova_db_create() {

    echo '
    # ------------------------------------------------------------------------------
    ### ctrl_nova_db_create!!!
    # ------------------------------------------------------------------------------'

    mysql -uroot -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE nova;'
    mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$MYSQL_NOVA_PASS';"
    mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$MYSQL_NOVA_PASS';"

    echo '>>> check result------------------------------------------------------'
    mysql -u root -p${MYSQL_ROOT_PASS} -h localhost -e "show databases;"
    echo '# --------------------------------------------------------------------'

}



ctrl_nova_configure() {

    echo "
    # ------------------------------------------------------------------------------
    ### ctrl_nova_configure(${NOVA_CONF}) !!!
    # ------------------------------------------------------------------------------"

    backup_org ${NOVA_CONF}

cat > ${NOVA_CONF} <<EOF
# ------------------------------------------------------------------------------
[DEFAULT]
dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/var/lock/nova
root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf
verbose=True
debug=True
force_dhcp_release=True

use_syslog = True
syslog_log_facility = LOG_LOCAL0

api_paste_config=${NOVA_API_PASTE}
enabled_apis=ec2,osapi_compute,metadata

#Libvirt and Virtualization
libvirt_use_virtio_for_bridges=True
connection_type=libvirt
libvirt_type=kvm

#Messaging
rabbit_host=${MYSQL_HOST}

#EC2 API Flags
ec2_host=${MYSQL_HOST}
ec2_dmz_host=${MYSQL_HOST}
ec2_private_dns_show_ip=True

#Network settings
network_api_class=nova.network.neutronv2.api.API
neutron_url=http://${MGMT_IP}:9696
neutron_auth_strategy=keystone
neutron_admin_tenant_name=service
neutron_admin_username=neutron
neutron_admin_password=neutron
neutron_admin_auth_url=http://${MGMT_IP}:5000/v2.0
libvirt_vif_driver=nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
linuxnet_interface_driver=nova.network.linux_net.LinuxOVSInterfaceDriver
#firewall_driver=nova.virt.libvirt.firewall.IptablesFirewallDriver
security_group_api=neutron
firewall_driver=nova.virt.firewall.NoopFirewallDriver

service_neutron_metadata_proxy=true
neutron_metadata_proxy_shared_secret=foo

#Metadata
metadata_host=${MYSQL_HOST}
metadata_listen=${MYSQL_HOST}
metadata_listen_port=8775

#Cinder #
volume_driver=nova.volume.driver.ISCSIDriver
volume_api_class=nova.volume.cinder.API
iscsi_helper=tgtadm
iscsi_ip_address=${CTRL_HOST}
volumes_path=/var/lib/nova/volumes

#Images
image_service=nova.image.glance.GlanceImageService
glance_api_servers=${GLANCE_HOST}:9292

#Scheduler
scheduler_default_filters=AllHostsFilter

#Auth
auth_strategy=keystone
keystone_ec2_url=http://${KEYSTONE_ENDPOINT}:5000/v2.0/ec2tokens

# RPC
rpc_backend=rabbit
rabbit_host=${CTRL_HOST}
rabbit_password=guest

#NoVNC
novnc_enabled=true
novncproxy_host=${API_IP}   # 외부접속을 허용하려면 controller public ip 사용해야 함
novncproxy_base_url=http://${API_IP}:6080/vnc_auto.html
novncproxy_port=6080

vncserver_proxyclient_address=${MGMT_IP}
vncserver_listen=0.0.0.0

[database]
connection=mysql://nova:${MYSQL_NOVA_PASS}@${MYSQL_HOST}/nova

[keystone_authtoken]
service_protocol=http
service_host=${MGMT_IP}
service_port=5000
auth_host=${MGMT_IP}
auth_port=35357
auth_protocol=http
auth_uri=http://${MGMT_IP}:35357/
admin_tenant_name=${SERVICE_TENANT}
admin_user=${NOVA_SERVICE_USER}
admin_password=${NOVA_SERVICE_PASS}
# ------------------------------------------------------------------------------
EOF

    echo '>>> check result
    # ------------------------------------------------------------------------------'
    cat $NOVA_CONF
    echo '
    # ------------------------------------------------------------------------------'

    chmod 0640 $NOVA_CONF
    chown nova:nova $NOVA_CONF

}

compute_nova_compute_configure() {

    echo '
    # ------------------------------------------------------------------------------
    ### compute_nova_compute_configure($NOVA_COMPUTE_CONF) !!!
    # ------------------------------------------------------------------------------'

    backup_org ${NOVA_COMPUTE_CONF}

cat > ${NOVA_COMPUTE_CONF} <<EOF
# ------------------------------------------------------------------------------
[DEFAULT]
compute_driver=libvirt.LibvirtDriver
[libvirt]
virt_type=kvm
# ------------------------------------------------------------------------------
EOF

    echo '>>> check result -----------------------------------------------------'
    cat $NOVA_COMPUTE_CONF
    echo '# --------------------------------------------------------------------'
}



ctrl_nova_restart() {
    echo '
    # ------------------------------------------------------------------------------
    ### ctrl_nova_restart() !!!
    # ------------------------------------------------------------------------------'

    echo '  nova db 동기화'
    nova-manage db sync

    echo '### nova service 재시작 !!!'

    for P in $(ls /etc/init/nova* | cut -d'/' -f4 | cut -d'.' -f1); do service ${P} restart; done

    echo '>>> check result -----------------------------------------------------'
    ps -ef | grep nova
    echo '# --------------------------------------------------------------------'

}