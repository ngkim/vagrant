#!/bin/bash

source "/vagrant/config/default.cfg"
source "/vagrant/include/print_util.sh"
source "/vagrant/include/12_config.sh"

install_ntp() {
	apt-get -y install ntp
}

config_ntp() {
	sed -i "s/server ntp.ubuntu.com/server ntp.ubuntu.com iburst/" /etc/ntp.conf
}

restart_ntp() {
	rm -rf /var/lib/ntp/ntp.conf.dhcp
	service ntp restart	
}

install_ntp
config_ntp
restart_ntp 