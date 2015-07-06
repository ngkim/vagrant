#!/bin/bash

source "/vagrant/config/default.cfg"
source "/vagrant/include/print_util.sh"
source "/vagrant/include/12_config.sh"

#==================================================================
print_title "KEYSTONE Verify operation"
#==================================================================
	
print_msg "For security reasons, disable the temporary authentication token mechanism:"
print_msg "Edit the /etc/keystone/keystone-paste.ini file" 
print_msg "  and remove admin_token_auth from the [pipeline:public_api], [pipeline:admin_api], and [pipeline:api_v3] sections."

unset OS_TOKEN OS_URL

openstack --os-auth-url http://controller:35357 \
  --os-project-domain-id default --os-user-domain-id default \
--os-project-name admin --os-username admin --os-auth-type password --os-password ${ADMIN_PASS}\
  token issue  
  
openstack --os-auth-url http://controller:35357 \
  --os-project-name admin --os-username admin --os-auth-type password --os-password ${ADMIN_PASS} \
  project list  

openstack --os-auth-url http://controller:35357 \
  --os-project-name admin --os-username admin --os-auth-type password --os-password ${ADMIN_PASS} \
  user list

#==================================================================
print_title "KEYSTONE Create OpenStack client environment scripts"
#==================================================================

create_openstack_rc() {
	cat > $HOME/admin-openrc.sh <<EOF
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=${ADMIN_PASS}
export OS_AUTH_URL=http://controller:35357/v3
EOF
}

create_openstack_rc

source $HOME/admin-openrc.sh
 
openstack token issue