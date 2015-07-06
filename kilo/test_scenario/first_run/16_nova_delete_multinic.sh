#!/bin/bash

source 'provider-net.ini'

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/openstack_rc
fi

VM_ID=`nova list | awk '/'$VM_NAME'/{print $2}'`

echo "nova delete $VM_ID"
nova delete $VM_ID
