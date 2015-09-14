#!/bin/bash

source "./00_check_config.sh"

#==================================================================
print_title "CEILOMETER - VERIFY"
#==================================================================

TMP_IMG="/tmp/cirros.img"

env_setup() {
	if [ -z ${OS_AUTH_URL+x} ]; then
    	source $OPENRC
	fi
}

# python-ceilometerclient 1.0.13 has bug which cannot deal with keystone v3
update_openstack_rc() {
	source "$WORK_HOME/config/default.cfg"
	unset OS_AUTH_URL
	
	cat > $HOME/admin-openrc.sh <<EOF
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=${ADMIN_PASS}
export OS_AUTH_URL=http://controller:35357/
EOF

	source $OPENRC
	
	echo "OS_AUTH_URL= $OS_AUTH_URL"
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
update_openstack_rc
list_meter
download_image_from_glance
list_meter
show_image_download_stat
remove_tmp_image