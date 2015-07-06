#!/bin/bash

source "ext-net.ini"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/openstack_rc
fi

echo 'neutron net-create $EXT_NET --shared --router:external=True'
neutron net-create $EXT_NET --shared --router:external=True

echo 'neutron subnet-create $EXT_NET --name $EXT_SUBNET \
  --allocation-pool start=$FLOATING_IP_START,end=$FLOATING_IP_END \
  --disable-dhcp --gateway $EXTERNAL_NETWORK_GATEWAY $EXTERNAL_NETWORK_CIDR'

neutron subnet-create $EXT_NET --name $EXT_SUBNET \
  --allocation-pool start=$FLOATING_IP_START,end=$FLOATING_IP_END \
  --disable-dhcp --gateway $EXTERNAL_NETWORK_GATEWAY $EXTERNAL_NETWORK_CIDR
