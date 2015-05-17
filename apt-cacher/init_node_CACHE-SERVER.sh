#!/bin/bash

sudo ifconfig eth1 192.168.11.1/24 up

#sudo apt-get install -y vlan iperf
#sudo modprobe 8021q
#sudo ifconfig eth2 up
#sudo vconfig add eth2 2001
#sudo ifconfig eth2.2001 192.168.1.1/24 up

sudo apt-get update

echo "1. install apt-cacher-ng"
sudo apt-get install -y apt-cacher-ng

echo "2. configure apt-cacher-ng"
sudo cat > /etc/apt-cacher-ng/acng.conf <<EOF
CacheDir: /var/cache/apt-cacher-ng
LogDir: /var/log/apt-cacher-ng

Port:3142
BindAddress: 0.0.0.0

Remap-debrep: file:deb_mirror*.gz /debian ; file:backends_debian # Debian Archives
Remap-uburep: file:ubuntu_mirrors /ubuntu ; file:backends_ubuntu # Ubuntu Archives

ReportPage: acng-report.html
PidFile: /var/run/apt-cacher-ng/pid
ExTreshold: 4

LocalDirs: acng-doc /usr/share/doc/apt-cacher-ng
EOF

echo "3. start apt-cacher-ng"
sudo /etc/init.d/apt-cacher-ng restart
