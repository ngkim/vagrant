#!/bin/bash

source "my.cfg"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

#MGMT_NET_ID=`neutron net-list | grep $MGMT_NET | awk '{print $2}'`
MGMT_NET_ID="9bc40430-3cda-419a-be10-2248df2141c7"
SRIOV_PORT_ID=`neutron port-list | grep $PORT_NAME | awk '{print $2}'`
IMAGE_ID="2ca8c490-d427-4ee0-8b85-e5022a35041d"

#echo "nova boot --flavor m1.medium --image ${IMAGE_ID} --nic net-id=$MGMT_NET_ID  --nic port-id=$SRIOV_PORT_ID --availability-zone daejeon-az:anode test-vm-sriov"
#nova boot --flavor m1.medium --image $IMAGE_ID --nic net-id=$MGMT_NET_ID  --nic port-id=$SRIOV_PORT_ID --availability-zone daejeon-az:anode test-vm-sriov
echo "nova boot --flavor m1.medium --image $IMAGE_ID --nic net-id=$MGMT_NET_ID  --nic port-id=$SRIOV_PORT_ID test-vm-sriov"
nova boot --flavor m1.medium --image $IMAGE_ID --nic net-id=$MGMT_NET_ID  --nic port-id=$SRIOV_PORT_ID test-vm-sriov
