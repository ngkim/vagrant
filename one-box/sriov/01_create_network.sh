#!/bin/bash

source "my.cfg"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

echo "neutron net-create --tenant-id $TENANT_ID --provider:physical_network=${PHYSNET} --provider:network_type=flat sriovTestNetwork"
neutron net-create --tenant-id $TENANT_ID --provider:physical_network=${PHYSNET} --provider:network_type=flat sriovTestNetwork
#echo "neutron net-create --tenant-id $TENANT_ID --provider:physical_network=${PHYSNET} --provider:network_type=vlan --provider:segmentation_id=83 sriovTestNetwork"
#neutron --debug net-create --tenant-id $TENANT_ID --provider:physical_network=${PHYSNET} --provider:network_type=vlan --provider:segmentation_id=83 sriovTestNetwork
