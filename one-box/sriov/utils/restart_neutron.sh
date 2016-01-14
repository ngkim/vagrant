#!/bin/bash

for process in $(ls /etc/init/neutron* | cut -d'/' -f4 | cut -d'.' -f1)
do
    if [ "$process" != "neutron-ovs-cleanup" ]; then
      echo -e ${green}${process}${normal}
      sudo stop ${process}
      sudo start ${process}
    fi
done
service openvswitch-switch restart
service dnsmasq restart

