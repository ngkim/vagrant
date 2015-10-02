#!/bin/bash

source "./00_check_config.sh"
source "$WORK_HOME/include/openstack/01_identity.sh"
source "$WORK_HOME/include/openstack/02_endpoint.sh"
source "$WORK_HOME/include/openstack/03_database.sh"
source "$WORK_HOME/include/openstack/04_neutron_ml2.sh"

#==================================================================
print_title "NEUTRON - CONFIG ML2 OVS"
#==================================================================
echo "NET_DRIVER= $NET_DRIVER"
echo " - FLAT_NETWORKS=   ${FLAT_NETWORKS}"
echo " - BRIDGE_LIST=     ${BRIDGE_LIST[*]}"
echo " - BRIDGE_MAPPINGS= ${BRIDGE_MAPPINGS}"

#==================================================================
#print_title "NEUTRON - CONFIG ML2 OVS"
#==================================================================
config_ml2_ovs

#==================================================================
#print_title "NEUTRON - RESTART"
#==================================================================
restart_neutron

