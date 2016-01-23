#!/bin/bash

source "./00_check_config.sh"

#==================================================================
print_title "HEAT - VERIFY"
#==================================================================

env_setup() {
	if [ -z ${OS_AUTH_URL+x} ]; then
    		source $OPENRC
	fi
}

config_stack() {
echo "
heat_template_version: 2014-10-16
description: Resources for WIMS
parameters:
    RPARM_imageId_WIMS:
        type: string
        description: \"image id.\"
    RPARM_mgmtVnetId_WIMS:
        type: string
        description: \"mgmt net\"
    RPARM_svcVnetId_WIMS:
        type: string
        description: \"server net\"
    RPARM_svcFixedIp_WIMS:
        type: string
        description: \"server ip.\"
resources:
    SERV_main_WIMS_1:
        type: OS::Nova::Server
        properties:
            name: WiMS_Controller
            image: { get_param: RPARM_imageId_WIMS }
            flavor: m1.large
            user_data: |
                #cloud-cofig
                hostname: WiMS_Controller
                fqdn: wims.onebox.kt.com
                manage_etc_hosts: true
            networks:
            -   port: { get_resource: PORT_mgmt_WIMS_1 }
            -   port: { get_resource: PORT_svc_WIMS_1 }
    PORT_mgmt_WIMS_1:
        type: OS::Neutron::Port
        properties:
            admin_state_up: true
            network_id: { get_param: RPARM_mgmtVnetId_WIMS }
    PORT_svc_WIMS_1:
        type: OS::Neutron::Port
        properties:
            admin_state_up: true
            network_id: { get_param: RPARM_svcVnetId_WIMS }
            fixed_ips:
            -   ip_address: { get_param: RPARM_svcFixedIp_WIMS }
outputs:
    ROUT_mgmtIp_WIMS_1:
        description: MGMT IP address of the SERV_main_WIMS
        value: { get_attr: [ PORT_mgmt_WIMS_1, fixed_ips, 0, ip_address ] }" > $TEST_STACK	
}

create_test_stack() {
	cmd="neutron net-list | awk '/${TENANT_NET}/{print \$2}'"
	run_commands_return $cmd
	local NET_ID=$RET

	cmd="neutron net-list | awk '/${ORG_NET}/{print \$2}'"
	run_commands_return $cmd
	local ORG_NET_ID=$RET
	
	cmd="heat stack-create -f $TEST_STACK -P \"RPARM_imageId_WIMS=${WIMS_IMAGE};RPARM_mgmtVnetId_WIMS=$NET_ID;RPARM_svcVnetId_WIMS=$ORG_NET_ID;RPARM_svcFixedIp_WIMS=$ORG_NETWORK_IP_TEST\" testStack"
	run_commands $cmd
}

list_stack() {
	cmd="heat stack-list"
	run_commands $cmd
}

env_setup
#config_test_stack
config_stack
create_test_stack
list_stack
