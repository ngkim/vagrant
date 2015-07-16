create_keystone_service() {
	openstack service create \
		--name keystone --description "OpenStack Identity" identity
}
 
create_keystone_endpoint() { 
	openstack endpoint create \
	  --publicurl http://controller:5000/v2.0 \
	  --internalurl http://controller:5000/v2.0 \
	  --adminurl http://controller:35357/v2.0 \
	  --region ${REGION_NAME} \
	  identity  
}

create_glance_service() {
	openstack service create \
		--name glance --description "OpenStack Image service" image
}
 
create_glance_endpoint() { 
	openstack endpoint create \
	--publicurl http://controller:9292 \
	--internalurl http://controller:9292 \
	--adminurl http://controller:9292 \
	--region ${REGION_NAME} \
	image
}

create_nova_service() {
	openstack service create --name nova \
		--description "OpenStack Compute" compute
}

create_nova_endpoint() {
	openstack endpoint create \
		--publicurl http://controller:8774/v2/%\(tenant_id\)s \
		--internalurl http://controller:8774/v2/%\(tenant_id\)s \
		--adminurl http://controller:8774/v2/%\(tenant_id\)s \
		--region ${REGION_NAME} \
		compute
}

create_neutron_service() {
	openstack service create --name neutron \
		--description "OpenStack Networking" network
}

create_neutron_endpoint() {
	openstack endpoint create \
	  --publicurl http://controller:9696 \
	  --adminurl http://controller:9696 \
	  --internalurl http://controller:9696 \
	  --region ${REGION_NAME} \
	  network
}

create_heat_service() {
	openstack service create \
		--name heat --description "Orchestration" orchestration
}

create_heat_cfn_service() {
	openstack service create --name heat-cfn \
		--description "Orchestration"  cloudformation
}
 
create_heat_orchestration_endpoint() { 
	openstack endpoint create \
	--publicurl http://controller:8004/v1/%\(tenant_id\)s \
	--internalurl http://controller:8004/v1/%\(tenant_id\)s \
	--adminurl http://controller:8004/v1/%\(tenant_id\)s \
	--region ${REGION_NAME} \
	orchestration
}

create_heat_cfn_endpoint() { 
	openstack endpoint create \
	--publicurl http://controller:8000/v1 \
	--internalurl http://controller:8000/v1 \
	--adminurl http://controller:8000/v1 \
	--region ${REGION_NAME} \
	cloudformation
}

create_ceilometer_service() {
	openstack service create --name ceilometer \
	--description "Telemetry" metering
}

create_ceilometer_endpoint() {
	openstack endpoint create \
	--publicurl http://controller:8777 \
	--internalurl http://controller:8777 \
	--adminurl http://controller:8777 \
	--region RegionOne \
	metering
}