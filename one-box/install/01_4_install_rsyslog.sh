#!/bin/bash 
source "./00_check_config.sh"

install_rsyslog() {
	apt-get install -y rsyslog
}

config_rsyslog() {
        cat >> /etc/rsyslog.d/60-nova.conf <<EOF
# prevent debug from dnsmasq with the daemon.none parameter
*.*;auth,authpriv.none,daemon.none              -/var/log/syslog
local0.*                    -/var/log/nova-all.log
EOF

        cat >> /etc/rsyslog.d/70-neutron.conf <<EOF
# prevent debug from dnsmasq with the daemon.none parameter
*.*;auth,authpriv.none,daemon.none              -/var/log/syslog
local4.*                    -/var/log/neutron-all.log
EOF

        cat >> /etc/rsyslog.d/80-error.conf <<EOF
# prevent debug from dnsmasq with the daemon.none parameter
*.error                    -/var/log/error-all.log
EOF

}

restart_rsyslog() {
	service rsyslog restart
}

install_rsyslog
config_rsyslog
restart_rsyslog
