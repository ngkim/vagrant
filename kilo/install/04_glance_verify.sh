#!/bin/bash

source "./00_check_config.sh"

#==================================================================
print_title "GLANCE - VERIFY"
#==================================================================

env_setup_glance() {
	source $OPENRC
	echo "export OS_IMAGE_API_VERSION=2" | tee -a $OPENRC
}

image_register_cirros() {
	mkdir -p /tmp/images
	wget -P /tmp/images http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
	
	glance image-create --name "cirros-0.3.4-x86_64" --file /tmp/images/cirros-0.3.4-x86_64-disk.img \
		--disk-format qcow2 --container-format bare --progress
}

glance_image_list() {
	glance image-list
}

cleanup() {
	rm -r /tmp/images
}

env_setup_glance
image_register_cirros
  
glance_image_list
cleanup