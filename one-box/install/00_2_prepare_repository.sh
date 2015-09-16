#!/bin/bash

source "./00_check_config.sh"

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

copy_deb_from_local_cache() {
	echo "cp -r /vagrant/archives /var/cache/apt/"
	cp -r /vagrant/archives /var/cache/apt/

	echo "dpkg -i /var/cache/apt/archives/*.deb"
	dpkg -i /var/cache/apt/archives/*.deb
}

install_repository
config_repository
update_repository