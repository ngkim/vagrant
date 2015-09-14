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

config_test_stack() {
echo "
heat_template_version: 2014-10-16
description: A simple server.
 
parameters:
  ImageID:
    type: string
    description: Image use to boot a server
  NetID:
    type: string
    description: Network ID for the server
 
resources:
  server:
    type: OS::Nova::Server
    properties:
      image: { get_param: ImageID }
      flavor: m1.tiny
      networks:
      - network: { get_param: NetID }
 
outputs:
  private_ip:
    description: IP address of the server in the private network
    value: { get_attr: [ server, first_address ] }" > $TEST_STACK	
	
}

create_test_stack() {
	cmd="neutron net-list | awk '/${TENANT_NET}/{print \$2}'"
	run_commands_return $cmd
	local NET_ID=$RET
	
	cmd="heat stack-create -f $TEST_STACK -P \"ImageID=${IMAGE_NAME_CIRROS};NetID=$NET_ID\" testStack"
	run_commands $cmd
}

list_stack() {
	cmd="heat stack-list"
	run_commands $cmd
}

env_setup
config_test_stack
create_test_stack
list_stack
