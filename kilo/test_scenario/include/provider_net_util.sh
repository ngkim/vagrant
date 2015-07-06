delete_provider_net() {
	NET_NAME=$1
    
	NET_ID=`neutron net-list | awk '/'$NET_NAME'/{print $2}'`
	if [ ! -z ${NET_ID} ]; then
		cmd="neutron net-delete $NET_ID"
		run_commands $cmd
	fi
}

delete_provider_subnet() {
	SBNET_NAME=$1
    
	SBNET_ID=`neutron subnet-list | awk '/'$SBNET_NAME'/{print $2}'`
	if [ ! -z ${SBNET_ID} ]; then
		cmd="neutron subnet-delete $SBNET_ID"
		run_commands $cmd
	fi
}

create_provider_net() {
    NET_NAME=$1
    PHYSNET_NAME=$2
    VLAN_ID=$3

	delete_provider_net $NET_NAME
	
	cmd="neutron net-create $NET_NAME \
		--provider:network_type vlan \
		--provider:physical_network $PHYSNET_NAME \
		--provider:segmentation_id $VLAN_ID"
		
	run_commands $cmd
}

create_provider_net_shared() {
    NET_NAME=$1
    PHYSNET_NAME=$2
    VLAN_ID=$3

	delete_provider_net $NET_NAME
	
	cmd="neutron net-create $NET_NAME \
		--provider:network_type vlan \
		--provider:physical_network $PHYSNET_NAME \
		--provider:segmentation_id $VLAN_ID \
        --shared"
		
	run_commands $cmd
}

create_provider_subnet() {
	NET_NAME=$1
    SBNET_NAME=$2
    SBNET_CIDR=$3
    
    delete_provider_subnet $SBNET_NAME
	
    cmd="neutron subnet-create $NET_NAME $SBNET_CIDR \
			--name $SBNET_NAME \
		 	--enable_dhcp False \
            --no-gateway"
	
	run_commands $cmd
}

create_provider_subnet_shared() {
	NET_NAME=$1
    SBNET_NAME=$2
    SBNET_CIDR=$3
    GW_IP=$4
    
    delete_provider_subnet $SBNET_NAME
	
    cmd="neutron subnet-create $NET_NAME $SBNET_CIDR \
			--name $SBNET_NAME \
		 	--enable_dhcp True \
                        --dns-nameservers list=true 8.8.8.8 8.8.8.9 \
            --gateway $GW_IP"
	
	run_commands $cmd
}
