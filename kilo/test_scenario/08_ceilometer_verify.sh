#!/bin/bash

source "ext-net.ini"
source "../config/default.cfg"
source "../include/print_util.sh"
source "../include/12_config.sh"
source "../include/command_util.sh"

#==================================================================
print_title "CEILOMETER - VERIFY"
#==================================================================

TMP_IMG="/tmp/cirros.img"

env_setup() {
	if [ -z ${OS_AUTH_URL+x} ]; then
    	source $OPENRC
	fi
}

list_meter() {
	cmd="ceilometer meter-list"
	run_commands $cmd
}

download_image_from_glance() {
	cmd="glance image-list | grep '${IMAGE_NAME_CIRROS}' | awk '{ print \$2 }'"
	run_commands_return $cmd
	local IMAGE_ID=$RET
	
	cmd="glance image-download $IMAGE_ID > ${TMP_IMG}"
	run_commands $cmd
}

show_image_download_stat() {
	#Retrieve usage statistics from the image.download meter:
	ceilometer statistics -m image.download -p 60
}

remove_tmp_image() {
	rm ${TMP_IMG}
}

env_setup
list_meter
download_image_from_glance
list_meter
show_image_download_stat
remove_tmp_image