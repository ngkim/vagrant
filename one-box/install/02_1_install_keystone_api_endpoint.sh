#!/bin/bash

source "./00_check_config.sh"
source "$WORK_HOME/include/openstack/01_identity.sh"
source "$WORK_HOME/include/openstack/02_endpoint.sh"

#==================================================================
print_title "Create the service entity and API endpoint"
#==================================================================

env_setup
create_keystone_service
create_keystone_endpoint

create_project admin "Admin"
create_user admin ${ADMIN_PASS}
create_role admin
add_user_to_role admin admin admin

create_project service "Service"

create_project demo "Demo"
create_user demo ${ADMIN_PASS}
create_role user
add_user_to_role demo demo user