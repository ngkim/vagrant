#!/bin/bash

source "ext-net.ini"
source "tenant-net.ini"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/openstack_rc
fi

echo 'neutron net-create $TENANT_NET'
neutron net-create $TENANT_NET

echo "neutron subnet-create $TENANT_NET --name $TENANT_SBNET \
  --gateway $TENANT_NETWORK_GW \
  --dns-nameserver $DNS_NAMESERVER \
  $TENANT_NETWORK_CIDR" 

neutron subnet-create $TENANT_NET \
	--name $TENANT_SBNET \
	--gateway $TENANT_NETWORK_GW \
  	--dns-nameserver $DNS_NAMESERVER \
	$TENANT_NETWORK_CIDR

echo "neutron router-create $TENANT_ROUTER"
neutron router-create $TENANT_ROUTER

echo "neutron router-interface-add $TENANT_ROUTER $TENANT_SBNET"
neutron router-interface-add $TENANT_ROUTER $TENANT_SBNET

echo "neutron router-gateway-set $TENANT_ROUTER $EXT_NET"
neutron router-gateway-set $TENANT_ROUTER $EXT_NET
