#!/bin/bash

source 'provider-net.ini'

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/openstack_rc
fi

VM_ID_GREEN=`nova list | awk '/'$VM_NAME-green'/{print $2}'`
VM_ID_ORANGE=`nova list | awk '/'$VM_NAME-orange'/{print $2}'`

if [ ! -z $VM_ID_GREEN ]; then
	echo "nova delete $VM_ID_GREEN"
	nova delete $VM_ID_GREEN
fi

if [ ! -z $VM_ID_ORANGE ]; then
	echo "nova delete $VM_ID_ORANGE"
	nova delete $VM_ID_ORANGE
fi
