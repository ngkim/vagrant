/bin/bash

source "./00_check_config.sh"
source "$WORK_HOME/include/print_util.sh"
source "$WORK_HOME/include/openstack/01_identity.sh"
source "$WORK_HOME/include/openstack/02_endpoint.sh"
source "$WORK_HOME/include/openstack/03_database.sh"

#==================================================================
print_title "NOVA COMPUTE - VERIFY"
#==================================================================

source $OPENRC

cmd="nova service-list"
run_commands $cmd

cmd="nova endpoints"
run_commands $cmd

cmd="nova image-list"
run_commands $cmd
