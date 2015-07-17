#!/bin/bash

run() {
	./00_prepare_networking.sh
	
	./00_prepare_repository.sh
	
	./01_install_database.sh
	
	./01_install_msgQ.sh
	
	./01_install_ntp.sh
	
	./02_install_keystone.sh
	
	./02_1_install_keystone_api_endpoint.sh
	
	./02_2_verify_keystone.sh
	
	./04_glance_install.sh
	
	./04_glance_verify.sh
	
	./05_1_nova_install_controller.sh
	
	./05_2_nova_install_compute.sh
	
	./06_1_neutron_install_controller.sh
	
	./06_2_neutron_install_network.sh
	
	./06_3_neutron_install_compute.sh
	
	./07_horizon_install.sh
	
	./08_heat_install.sh
	
	#./09_1_ceilometer_install_controller_mongodb.sh
	
	#./09_2_ceilometer_install_controller.sh
	
	#./09_3_ceilometer_install_compute.sh
	
	#./09_4_ceilometer_install_image.sh
}

run
