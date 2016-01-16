#!/bin/bash

source "my.cfg"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

#MGMT_NET_ID=`neutron net-list | grep $MGMT_NET | awk '{print $2}'`
MGMT_NET_ID="9bc40430-3cda-419a-be10-2248df2141c7"
SRIOV_PORT_ID=`neutron port-list | grep $PORT_NAME | awk '{print $2}'`
IMAGE_ID="2ca8c490-d427-4ee0-8b85-e5022a35041d"

echo "nova delete test-vm-sriov"
nova delete test-vm-sriov

echo "neutron port-delete $PORT_NAME"
neutron port-delete $PORT_NAME

echo "neutron subnet-delete $SBNET_NAME"
neutron subnet-delete $SBNET_NAME

echo "neutron net-delete $NET_NAME"
neutron net-delete $NET_NAME
