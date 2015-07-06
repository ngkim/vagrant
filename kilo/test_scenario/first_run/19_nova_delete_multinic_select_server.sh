#!/bin/bash

source 'provider-net.ini'

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/openstack_rc
fi

echo "nova list | awk '/'$VM_NAME'/{print $2}'"
VM_ID=`nova list | awk '/'$VM_NAME'/{print $2}'`
echo "VM_ID= $VM_ID"

if [ ! -z ${VM_ID} ]; then
	echo "nova delete $VM_ID"
	nova delete $VM_ID
fi
