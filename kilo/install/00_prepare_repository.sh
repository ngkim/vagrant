#!/bin/bash

source "/vagrant/config/default.cfg"
source "/vagrant/include/print_util.sh"
source "/vagrant/include/12_config.sh"

install_repository() {
	apt-get install -y ubuntu-cloud-keyring crudini
}

config_repository() {
	echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" \
		"trusty-updates/kilo main" > /etc/apt/sources.list.d/cloudarchive-kilo.list
}

update_repository() { 
	apt-get update && apt-get dist-upgrade -y
}

install_repository
config_repository
update_repository