#!/bin/bash

source "./00_check_config.sh"
source "$WORK_HOME/include/openstack/01_identity.sh"
source "$WORK_HOME/include/openstack/02_endpoint.sh"
source "$WORK_HOME/include/openstack/03_database.sh"

#==================================================================
print_title "NEUTRON - VERIFY"
#==================================================================

source $OPENRC
neutron ext-list
