#!/bin/bash

IP="211.224.204.134"
SBNET="255.255.255.128"
GW="211.224.204.129"
DNS="8.8.8.8"
NIC="eth1"

cat > /etc/network/interfaces.d/$NIC.cfg <<EOF
# The primary network interface
auto $NIC
iface $NIC inet static
        address $IP
        netmask $SBNET
        gateway $GW
        # dns-* options are implemented by the resolvconf package, if installed
        dns-nameservers $DNS
EOF
ifup $NIC

config_nic() {
  ifconfig eth1 $IP
  ip route del default
  ip route add default via $GW
}

apt-get install -y git
mkdir -p /root/workspace
cd /root/workspace
git clone https://github.com/ngkim/stack_ops.git
cd /root/workspace/stack_ops/iptables
./apply-iptables.sh

# ntp config
apt-get install -y ntp
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
sed -i "s/server ntp.ubuntu.com/server ntp.ubuntu.com iburst/" /etc/ntp.conf
service ntp restart
