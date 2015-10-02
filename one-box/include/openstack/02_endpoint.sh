create_keystone_service() {
	openstack service create \
		--name keystone --description "OpenStack Identity" identity
}
 
create_keystone_endpoint() { 
	openstack endpoint create \
	  --publicurl http://${BOXNAME}:5000/v2.0 \
	  --internalurl http://${BOXNAME}:5000/v2.0 \
	  --adminurl http://${BOXNAME}:35357/v2.0 \
	  --region ${REGION_NAME} \
	  identity  
}

create_glance_service() {
	openstack service create \
		--name glance --description "OpenStack Image service" image
}
 
create_glance_endpoint() { 
	openstack endpoint create \
	--publicurl http://${BOXNAME}:9292 \
	--internalurl http://${BOXNAME}:9292 \
	--adminurl http://${BOXNAME}:9292 \
	--region ${REGION_NAME} \
	image
}

create_nova_service() {
	openstack service create --name nova \
		--description "OpenStack Compute" compute
}

create_nova_endpoint() {
	openstack endpoint create \
		--publicurl http://${BOXNAME}:8774/v2/%\(tenant_id\)s \
		--internalurl http://${BOXNAME}:8774/v2/%\(tenant_id\)s \
		--adminurl http://${BOXNAME}:8774/v2/%\(tenant_id\)s \
		--region ${REGION_NAME} \
		compute
}

create_neutron_service() {
	openstack service create --name neutron \
		--description "OpenStack Networking" network
}

create_neutron_endpoint() {
	openstack endpoint create \
	  --publicurl http://${BOXNAME}:9696 \
	  --adminurl http://${BOXNAME}:9696 \
	  --internalurl http://${BOXNAME}:9696 \
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
	--publicurl http://${BOXNAME}:8004/v1/%\(tenant_id\)s \
	--internalurl http://${BOXNAME}:8004/v1/%\(tenant_id\)s \
	--adminurl http://${BOXNAME}:8004/v1/%\(tenant_id\)s \
	--region ${REGION_NAME} \
	orchestration
}

create_heat_cfn_endpoint() { 
	openstack endpoint create \
	--publicurl http://${BOXNAME}:8000/v1 \
	--internalurl http://${BOXNAME}:8000/v1 \
	--adminurl http://${BOXNAME}:8000/v1 \
	--region ${REGION_NAME} \
	cloudformation
}

create_ceilometer_service() {
	openstack service create --name ceilometer \
	--description "Telemetry" metering
}

create_ceilometer_endpoint() {
	openstack endpoint create \
	--publicurl http://${BOXNAME}:8777 \
	--internalurl http://${BOXNAME}:8777 \
	--adminurl http://${BOXNAME}:8777 \
	--region RegionOne \
	metering
}
