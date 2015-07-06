#!/bin/bash

source "ext-net.ini"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/openstack_rc
fi

SBNET_ID=`neutron subnet-list | awk '/'$EXT_SUBNET'/{print $2}'`
NET_ID=`neutron net-list | awk '/'$EXT_NET'/{print $2}'`

echo 'neutron subnet-delete '$SBNET_ID
neutron subnet-delete $SBNET_ID

echo 'neutron net-delete '$NET_ID
neutron net-delete $NET_ID
