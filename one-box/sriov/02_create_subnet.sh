#!/bin/bash

source "my.cfg"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

NET_ID=`neutron net-list | grep $NET_NAME | awk '{print $2}'`

echo "neutron subnet-create --tenant-id $TENANT_ID --ip_version 4 --gateway 11.0.27.1 --name $SBNET_NAME $NET_ID 11.0.27.0/24"
neutron subnet-create --tenant-id $TENANT_ID --ip_version 4 --gateway 11.0.27.1 --name $SBNET_NAME $NET_ID 11.0.27.0/24
