#!/bin/bash

source "my.cfg"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

echo "neutron port-create $NET_NAME --binding:vnic-type direct --name $PORT_NAME"
neutron port-create $NET_NAME --binding:vnic-type direct --name $PORT_NAME
