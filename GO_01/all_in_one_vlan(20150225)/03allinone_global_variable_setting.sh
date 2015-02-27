#!/bin/bash

echo '
################################################################################

    오픈스택 설치시 참조변수들 설정
    
################################################################################
'

export DEBIAN_FRONTEND=noninteractive

#
#   오픈스택 open-vswitch 사용을 위한 변수 설정
#     => ctrl_ovs_install.sh, ctrl_neutron_install.sh 에서 사용됨  

#
# vlan을 위한 physical network 
#   -> 여기에 선언된 각각의 네트워크에 4096개의 vlan을 제공할 수 있슴

# vlan용 physical external network 접속 네트워크
PHY_EXT_NET=physnet_ext

# vlan용 physical guest network range:
PHY_GUEST_NET=physnet_guest
PHY_GUEST_NET_RANGE=${PHY_GUEST_NET}:2001:4000

# vlan용 physical lan network range
PHY_LAN_NET=physnet_lan
PHY_LAN_NET_RANGE=${PHY_LAN_NET}:10:2000

# vlan용 physical wan network range
PHY_WAN_NET=physnet_wan
PHY_WAN_NET_RANGE=${PHY_WAN_NET}:10:2000

#
# ovs switch logical bridge
 
LOG_EXT_BR=br-ex        # external network access bridge
LOG_GUEST_BR=br-guest   # guest network access bridge
LOG_LAN_BR=br-lan       # lan network access bridge
LOG_WAN_BR=br-wan       # wan network access bridge

# ovs switch integration bridge
LOG_INT_BR=br-int


echo "
--------------------------------------------------------------------------------
 오픈스택 open-vswitch 설정 내역
--------------------------------------------------------------------------------"
printf "%30s -> %s \n" PHY_EXT_NET $PHY_EXT_NET
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" PHY_GUEST_NET $PHY_GUEST_NET
printf "%30s -> %s \n" PHY_GUEST_NET_RANGE $PHY_GUEST_NET_RANGE
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" PHY_LAN_NET $PHY_LAN_NET
printf "%30s -> %s \n" PHY_LAN_NET_RANGE $PHY_LAN_NET_RANGE
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" PHY_WAN_NET $PHY_WAN_NET
printf "%30s -> %s \n" PHY_WAN_NET_RANGE $PHY_WAN_NET_RANGE
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" LOG_INT_BR $LOG_INT_BR
printf "%30s -> %s \n" LOG_EXT_BR $LOG_EXT_BR
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" LOG_GUEST_BR $LOG_GUEST_BR
printf "%30s -> %s \n" LOG_LAN_BR $LOG_LAN_BR
printf "%30s -> %s \n" LOG_WAN_BR $LOG_WAN_BR
echo "--------------------------------------------------------------------------"

#
# 오픈스택 설치에 필요한 변수리스트

KEYSTONE_ENDPOINT=$CTRL_HOST

# LJG: 맨처음 keystone을 설치하기 전에 꼭 필요
#      사용자가 설정되면 일반적인 변수설정파일(rc)을 사용 
SERVICE_TOKEN=icehouse_service_token
SERVICE_ENDPOINT=http://${KEYSTONE_ENDPOINT}:35357/v2.0/

REGION=regionOne
SERVICE_TENANT_NAME=service
MONGO_KEY=mongo_foo
PASSWORD=ohhberry3333

ADMIN_TENANT=admin

ADMIN_USER=admin
ADMIN_PASS=$PASSWORD
ADMIN_ROLE=admin
MEMBER_USER=member
MEMBER_PASS=member1234
MEMBER_ROLE=member

echo "
--------------------------------------------------------------------------------
 오픈스택 주요계정변수 설정 내역 
--------------------------------------------------------------------------------"

echo "--------------------------------------------------------------------------"
printf "%30s -> %s \n" CTRL_HOST $CTRL_HOST
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" SERVICE_TOKEN $SERVICE_TOKEN
printf "%30s -> %s \n" SERVICE_ENDPOINT $SERVICE_ENDPOINT
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" KEYSTONE_ENDPOINT $KEYSTONE_ENDPOINT
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" SERVICE_TENANT_NAME $SERVICE_TENANT_NAME
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" MONGO_KEY $MONGO_KEY
printf "%30s -> %s \n" PASSWORD $PASSWORD
echo "--------------------------------------------------------------------------"

# ask_continue_stop

#
# MySQL variable

MYSQL_HOST=$CTRL_HOST
MYSQL_ROOT_PASS=$PASSWORD

MYSQL_NOVA_PASS=nova
MYSQL_NEUTRON_PASS=neutron
MYSQL_KEYSTONE_PASS=keystone
MYSQL_GLANCE_PASS=glance
MYSQL_CINDER_PASS=cinder

echo "
--------------------------------------------------------------------------------
 MySQL 변수 설정 내역
--------------------------------------------------------------------------------"
printf "%30s -> %s \n" MYSQL_HOST $MYSQL_HOST
printf "%30s -> %s \n" MYSQL_ROOT_PASS $MYSQL_ROOT_PASS
printf "%30s -> %s \n" MYSQL_NOVA_PASS $MYSQL_NOVA_PASS
printf "%30s -> %s \n" MYSQL_NEUTRON_PASS $MYSQL_NEUTRON_PASS
printf "%30s -> %s \n" MYSQL_KEYSTONE_PASS $MYSQL_KEYSTONE_PASS
printf "%30s -> %s \n" MYSQL_GLANCE_PASS $MYSQL_GLANCE_PASS
printf "%30s -> %s \n" MYSQL_CINDER_PASS $MYSQL_CINDER_PASS
echo "--------------------------------------------------------------------------"

# ask_continue_stop

# -----------------------------------------------------------------------------
# 오픈스택 서비스 계정 설정
# -----------------------------------------------------------------------------

SERVICE_TENANT=service

NOVA_SERVICE_USER=nova
NOVA_SERVICE_PASS=nova

GLANCE_SERVICE_USER=glance
GLANCE_SERVICE_PASS=glance

CINDER_SERVICE_USER=cinder
CINDER_SERVICE_PASS=cinder

NEUTRON_SERVICE_USER=neutron
NEUTRON_SERVICE_PASS=neutron

echo "
--------------------------------------------------------------------------------
 오픈스택 서비스 계정 설정 내역
--------------------------------------------------------------------------------"
printf "%30s -> %s \n" SERVICE_TENANT $SERVICE_TENANT
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" NOVA_SERVICE_USER $NOVA_SERVICE_USER
printf "%30s -> %s \n" NOVA_SERVICE_PASS $NOVA_SERVICE_PASS
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" GLANCE_SERVICE_USER $GLANCE_SERVICE_USER
printf "%30s -> %s \n" GLANCE_SERVICE_PASS $GLANCE_SERVICE_PASS
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" CINDER_SERVICE_USER $CINDER_SERVICE_USER
printf "%30s -> %s \n" CINDER_SERVICE_PASS $CINDER_SERVICE_PASS
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" NEUTRON_SERVICE_USER $NEUTRON_SERVICE_USER
printf "%30s -> %s \n" NEUTRON_SERVICE_PASS $NEUTRON_SERVICE_PASS
echo "--------------------------------------------------------------------------"


# --------------------------------------------------------------------------------
# 오픈스택 호스트 및 이미지 변수 설정 내역
# --------------------------------------------------------------------------------"
VNC_HOST=$API_IP
GLANCE_HOST=$CTRL_HOST

# openstack 설치시 default로 설치할 images
CIRROS_IMAGE="cirros-0.3.0-x86_64-disk.img"
UBUNTU_IMAGE="trusty-server-cloudimg-amd64-disk1.img"

echo "
--------------------------------------------------------------------------------
 오픈스택 호스트 및 이미지 변수 설정 내역
--------------------------------------------------------------------------------"
printf "%30s -> %s \n" VNC_HOST $VNC_HOST
printf "%30s -> %s \n" GLANCE_HOST $GLANCE_HOST
printf "%30s -> %s \n" CIRROS_IMAGE $CIRROS_IMAGE
printf "%30s -> %s \n" UBUNTU_IMAGE $UBUNTU_IMAGE
echo "--------------------------------------------------------------------------"
# ask_continue_stop


#
# 오픈스택 콤포넌트 구성정보 파일 정보 설정

MY_SQL_CONF=/etc/mysql/my.cnf
NIC_CONF=/etc/network/interfaces

KEYSTONE_CONF=/etc/keystone/keystone.conf 

GLANCE_API_CONF=/etc/glance/glance-api.conf
GLANCE_REGISTRY_CONF=/etc/glance/glance-registry.conf
GLANCE_API_INI=/etc/glance/glance-api-paste.ini
GLANCE_REGISTRY_INI=/etc/glance/glance-registry-paste.ini

CINDER_CONF=/etc/cinder/cinder.conf
CINDER_API=/etc/cinder/api-paste.ini

HORIZON_CONF=/etc/openstack-dashboard/local_settings.py
APACHE_CONF=/etc/apache2/conf-enabled/openstack-dashboard.conf

NOVA_CONF=/etc/nova/nova.conf
NOVA_COMPUTE_CONF=/etc/nova/nova-compute.conf
NOVA_API_PASTE=/etc/nova/api-paste.ini

NEUTRON_CONF=/etc/neutron/neutron.conf
NEUTRON_PLUGIN_ML2_CONF_INI=/etc/neutron/plugins/ml2/ml2_conf.ini
NEUTRON_L3_AGENT_INI=/etc/neutron/l3_agent.ini
NEUTRON_DHCP_AGENT_INI=/etc/neutron/dhcp_agent.ini
NEUTRON_METADATA_AGENT_INI=/etc/neutron/metadata_agent.ini

RSYSLOG_CONF=/etc/rsyslog.conf
ROOTWRAP_CONF=/etc/cinder/rootwrap.conf

echo "
--------------------------------------------------------------------------------
 오픈스택 콤포넌트 구성정보 파일 정보 설정 내역
--------------------------------------------------------------------------------"

printf "%30s -> %s \n" KEYSTONE_CONF $KEYSTONE_CONF
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" GLANCE_API_CONF $GLANCE_API_CONF
printf "%30s -> %s \n" GLANCE_REGISTRY_CONF $GLANCE_REGISTRY_CONF
printf "%30s -> %s \n" GLANCE_API_INI $GLANCE_API_INI
printf "%30s -> %s \n" GLANCE_REGISTRY_INI $GLANCE_REGISTRY_INI
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" CINDER_CONF $CINDER_CONF
printf "%30s -> %s \n" CINDER_API $CINDER_API
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" NOVA_CONF $NOVA_CONF
printf "%30s -> %s \n" NOVA_COMPUTE_CONF $NOVA_COMPUTE_CONF
printf "%30s -> %s \n" NOVA_API_PASTE $NOVA_API_PASTE
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" NEUTRON_CONF $NEUTRON_CONF
printf "%30s -> %s \n" NEUTRON_PLUGIN_ML2_CONF_INI $NEUTRON_PLUGIN_ML2_CONF_INI
printf "%30s -> %s \n" NEUTRON_L3_AGENT_INI $NEUTRON_L3_AGENT_INI
printf "%30s -> %s \n" NEUTRON_DHCP_AGENT_INI $NEUTRON_DHCP_AGENT_INI
printf "%30s -> %s \n" NEUTRON_METADATA_AGENT_INI $NEUTRON_METADATA_AGENT_INI
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" HORIZON_CONF $HORIZON_CONF
printf "%30s -> %s \n" APACHE_CONF $APACHE_CONF
printf "%s\n" "----------------------------------"
printf "%30s -> %s \n" MY_SQL_CONF $MY_SQL_CONF
printf "%30s -> %s \n" NIC_CONF $NIC_CONF
printf "%30s -> %s \n" RSYSLOG_CONF $RSYSLOG_CONF
printf "%30s -> %s \n" ROOTWRAP_CONF $ROOTWRAP_CONF
echo "--------------------------------------------------------------------------"


ask_continue_stop