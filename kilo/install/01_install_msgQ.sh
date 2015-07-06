#!/bin/bash

source "/vagrant/config/default.cfg"
source "/vagrant/include/print_util.sh"
source "/vagrant/include/12_config.sh"

#-----------------------------------------------------------------------------------------------------------------------
print_title "MESSAGE QUEUE"
#-----------------------------------------------------------------------------------------------------------------------

install_msgQ() {
	apt-get install -y rabbitmq-server
}

add_msgQ_user() {
	rabbitmqctl add_user openstack ${RABBIT_PASS}
	rabbitmqctl set_permissions openstack ".*" ".*" ".*"
}

install_msgQ
add_msgQ_user