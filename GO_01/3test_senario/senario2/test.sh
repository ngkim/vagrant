#!/bin/bash

export OS_TENANT_NAME=jingoo    
export OS_USERNAME=jingoo
export OS_PASSWORD=jingoo1234
export OS_AUTH_URL=http://10.0.0.101:5000/v2.0/
export OS_NO_CACHE=1
export OS_VOLUME_API_VERSION=2

env | grep OS


cli="neutron port-create global_mgmt_net --fixed-ip ip_address=10.10.10.111"
echo $cli
eval $cli


 
 
net_name=global_mgmt_net
net_id=$(neutron net-list | grep "$net_name " | awk '{print $2}')
printf "net_name[%s] -> net_id[%s]\n" $net_name $net_id


subnet_name=global_mgmt_subnet
subnet_id=$(neutron subnet-list | grep "$subnet_name " | awk '{print $2}')
printf "net_name[%s] -> net_id[%s]\n" $subnet_name $subnet_id


