#!/bin/bash

source ./common_lib.sh

#
# 고객이름 변수
zo_user=$1

#
# openstack CLI env variable  
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=ohhberry3333
export OS_AUTH_URL=http://10.0.0.101:5000/v2.0/
export OS_NO_CACHE=1
export OS_VOLUME_API_VERSION=2

REGION=regionOne
DOMAIN=seocho.seoul.zo.kt
HOST_AGGR_NAME=zo-aggr
AVAILABILITY_ZONE=seocho-az
CNODE01=cnode01
CNODE02=cnode02
CNODE03=cnode03

# admin account info
ADMIN_TENANT_NAME=$OS_TENANT_NAME
ADMIN_USER_NAME=$OS_USERNAME
ADMIN_USER_PASS=$OS_PASSWORD

# customer info
GUEST_TENANT_NAME=$zo_user
GUEST_USER_NAME=$zo_user
GUEST_USER_PASS=${zo_user}1234
GUEST_ROLE_NAME=member
GUEST_KEY=${zo_user}key
GUEST_KEY_FILE=${GUEST_KEY}.pub

# shared public net
PUBLIC_NET=public_net
FLOATING_IP_POOL_NAME=$PUBLIC_NET

# customer guest net info
GUEST_NET=${zo_user}_guest_net
GUEST_SUBNET=${zo_user}_guest_subnet
GUEST_SUBNET_CIDR=10.10.10.0/24
GUEST_ROUTER=${zo_user}_guest_router

# openstack hybrid physical network
HYBRID_PHYSNET_NAME=physnet_hybrid

# red shared network
RED_NET=red_shared_public_net

#
# green network info
get_random_num_between green_vlan_id 500 1500
GREEN_NET=${zo_user}_green_net
GREEN_NET_VLAN=$green_vlan_id
GREEN_SUBNET=${zo_user}_green_subnet
# LJG: ipcalc를 이용하여 항상 검증할 것
GREEN_SUBNET_CIDR=192.168.0.0/24
GREEN_SUBNET_IP_POOL_START=192.168.0.1
GREEN_SUBNET_IP_POOL_END=192.168.0.224

#
# orange network info
#get_random_num_between orange_vlan_id 500 1500
#if [$green_vlan_id == $orange_vlan_id]; then
#    let "orange_vlan_id+=1"
#fi
let "orange_vlan_id = $green_vlan_id + 1"
ORANGE_NET=${zo_user}_orange_net
ORANGE_NET_VLAN=$orange_vlan_id
ORANGE_SUBNET=${zo_user}_orange_subnet
#ORANGE_SUBNET_CIDR=192.168.0.224/27
ORANGE_SUBNET_CIDR=192.168.0.0/24
ORANGE_SUBNET_IP_POOL_START=192.168.0.224
ORANGE_SUBNET_IP_POOL_END=192.168.0.255

UTM_IMAGE=ubuntu-12.04
UTM_IMAGE=Base_endian_kbell
UTM_IMAGE=endian_221.145.180.82
CLIENT_IMAGE=ubuntu-12.04
SERVER_IMAGE=ubuntu-12.04


echo "##########################################################################"    
echo "(#) 프로그램 구성변수 설명"
echo "##########################################################################"    

echo   "# openstack CLI env variable"
printf "    %-20s => %s  \n" OS_TENANT_NAME $OS_TENANT_NAME
printf "    %-20s => %s  \n" OS_USERNAME $OS_USERNAME
printf "    %-20s => %s  \n" OS_PASSWORD $OS_PASSWORD
printf "    %-20s => %s  \n" OS_AUTH_URL $OS_AUTH_URL
printf "    %-20s => %s  \n" OS_NO_CACHE $OS_NO_CACHE
echo

echo   "# $DOMAIN region/az-zone info"
printf "    %-20s => %s  \n" REGION $REGION
printf "    %-20s => %s  \n" HOST_AGGR_NAME $HOST_AGGR_NAME
printf "    %-20s => %s  \n" AVAILABILITY_ZONE $AVAILABILITY_ZONE
echo
printf "    %-20s => %s  \n" CNODE01 $CNODE01
printf "    %-20s => %s  \n" CNODE02 $CNODE02
printf "    %-20s => %s  \n" CNODE03 $CNODE03

echo   "# admin account info"
printf "    %-20s => %s  \n" ADMIN_TENANT_NAME $ADMIN_TENANT_NAME
printf "    %-20s => %s  \n" ADMIN_USER_NAME $ADMIN_USER_NAME
printf "    %-20s => %s  \n" ADMIN_USER_PASS $ADMIN_USER_PASS
echo

echo   "# customer info"
printf "    %-20s => %s  \n" GUEST_TENANT_NAME $GUEST_TENANT_NAME
printf "    %-20s => %s  \n" GUEST_USER_NAME $GUEST_USER_NAME
printf "    %-20s => %s  \n" GUEST_USER_PASS $GUEST_USER_PASS
printf "    %-20s => %s  \n" GUEST_ROLE_NAME $GUEST_ROLE_NAME
printf "    %-20s => %s  \n" GUEST_KEY $GUEST_KEY
printf "    %-20s => %s  \n" GUEST_KEY_FILE $GUEST_KEY_FILE
echo

echo   "# default network info"
printf "    %-20s => %s  \n" PUBLIC_NET $PUBLIC_NET
printf "    %-20s => %s  \n" GUEST_NET $GUEST_NET
printf "    %-20s => %s  \n" GUEST_SUBNET $GUEST_SUBNET
printf "    %-20s => %s  \n" GUEST_SUBNET_CIDR $GUEST_SUBNET_CIDR
printf "    %-20s => %s  \n" GUEST_ROUTER $GUEST_ROUTER
echo

echo   "# hybrid network info"
printf "    %-20s => %s  \n" HYBRID_PHYSNET_NAME $HYBRID_PHYSNET_NAME
echo
printf "    %-20s => %s  \n" RED_NET $RED_NET
echo
printf "    %-20s => %s  \n" GREEN_NET $GREEN_NET
printf "    %-20s => %s  \n" GREEN_NET_VLAN $GREEN_NET_VLAN
printf "    %-20s => %s  \n" GREEN_SUBNET $GREEN_SUBNET
printf "    %-30s => %s  \n" GREEN_SUBNET_CIDR $GREEN_SUBNET_CIDR
printf "    %-30s => %s  \n" GREEN_SUBNET_IP_POOL_START $GREEN_SUBNET_IP_POOL_START
printf "    %-30s => %s  \n" GREEN_SUBNET_IP_POOL_END $GREEN_SUBNET_IP_POOL_END
echo
printf "    %-20s => %s  \n" ORANGE_NET $ORANGE_NET
printf "    %-20s => %s  \n" ORANGE_NET_VLAN $ORANGE_NET_VLAN
printf "    %-20s => %s  \n" ORANGE_SUBNET $ORANGE_SUBNET
printf "    %-30s => %s  \n" ORANGE_SUBNET_NET_CIDR $ORANGE_SUBNET_NET_CIDR
printf "    %-30s => %s  \n" ORANGE_SUBNET_IP_POOL_START $ORANGE_SUBNET_IP_POOL_START
printf "    %-30s => %s  \n" ORANGE_SUBNET_IP_POOL_END $ORANGE_SUBNET_IP_POOL_END
echo

echo   "# customer image info"
printf "    %-20s => %s  \n" UTM_IMAGE $UTM_IMAGE
printf "    %-20s => %s  \n" CLIENT_IMAGE $CLIENT_IMAGE
printf "    %-20s => %s  \n" SERVER_IMAGE $SERVER_IMAGE
echo