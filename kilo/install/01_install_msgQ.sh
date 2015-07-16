#!/bin/bash

source "./00_check_config.sh"

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