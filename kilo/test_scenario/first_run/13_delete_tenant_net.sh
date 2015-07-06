#!/bin/bash

source "ext-net.ini"
source "tenant-net.ini"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/openstack_rc
fi

neutron router-list
TENANT_ROUTER_ID=`neutron router-list | awk '/'$TENANT_ROUTER'/{print $2}'`
TENANT_SBNET_ID=`neutron subnet-list | awk '/'$TENANT_SBNET'/{print $2}'`
TENANT_NET_ID=`neutron net-list | awk '/'$TENANT_NET'/{print $2}'`

echo "neutron router-gateway-clear $TENANT_ROUTER_ID"
neutron router-gateway-clear $TENANT_ROUTER_ID

echo "neutron router-interface-delete $TENANT_ROUTER_ID $TENANT_SBNET"
neutron router-interface-delete $TENANT_ROUTER_ID $TENANT_SBNET

echo "neutron router-delete $TENANT_ROUTER_ID"
neutron router-delete $TENANT_ROUTER_ID

echo 'neutron subnet-delete '$TENANT_SBNET_ID
neutron subnet-delete $TENANT_SBNET_ID

echo 'neutron net-delete '$TENANT_NET_ID
neutron net-delete $TENANT_NET_ID


