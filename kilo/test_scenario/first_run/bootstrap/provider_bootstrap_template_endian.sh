#!/bin/bash

file_name=$1
_nic_grn=$2
_nic_org=$3
_ip=$4
_cidr_grn=$5
_nic_red=$6
_red_ip=$7

cat > $file_name <<EOF
#!/bin/bash

echo "
################################################################################
#
#   VM :: User Data Action
#
################################################################################
"

echo "
# ---------------------------------------------------
# 1. install tools
# ---------------------------------------------------
"

#apt-get -y update  
#apt-get -y install iperf ifstat sysstat bridge-utils

echo "
# --------------------------------------------------- 
# 2. nic activate
# ---------------------------------------------------
"
ifconfig $_nic_grn up
ifconfig $_nic_org up

echo "
# --------------------------------------------------- 
# 3. create bridge & allocate IP
# ---------------------------------------------------
"
brctl addbr br0
brctl addif br0 $_nic_grn
brctl addif br0 $_nic_org

ifconfig br0 $_ip up
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "
# --------------------------------------------------- 
# 4. configure red interface & apply nat rules
# ---------------------------------------------------
"
ifconfig $_nic_red $_red_ip up

iptables -A FORWARD -i br0 -o $_nic_red -s $_cidr_grn -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -F POSTROUTING
iptables -t nat -A POSTROUTING -o $_nic_red -j MASQUERADE

echo "
################################################################################
#
#   End User Data Action
#
################################################################################
"

EOF
