#!/bin/bash

file_name=$1
_nic_grn=$2
_ip_grn=$3
_nic_org=$4
_ip_org=$5
_nic_red=$6
_ip_red=$7
_ip_gw=$8

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
# 0. parameters 
# ---------------------------------------------------
#    _nic_grn= $_nic_grn
#    _ip_grn= $_ip_grn
#    _nic_org= $_nic_org
#    _ip_org= $_ip_org
#    _nic_grn= $_nic_red
#    _ip_red= $_ip_red
# ---------------------------------------------------
"

echo "
# ---------------------------------------------------
# 1. install tools
# ---------------------------------------------------
"

apt-get -y update  
apt-get -y install iperf ifstat sysstat bridge-utils

echo "
# --------------------------------------------------- 
# 2. nic activate
# ---------------------------------------------------
"
echo "ifconfig $_nic_grn up"
ifconfig $_nic_grn up
echo "ifconfig $_nic_org up"
ifconfig $_nic_org up

echo "
# --------------------------------------------------- 
# 3. create bridge br0 & allocate IP
# ---------------------------------------------------
"
echo "brctl addbr br0"
brctl addbr br0
echo "brctl addif br0 $_nic_grn"
brctl addif br0 $_nic_grn

echo "ifconfig br0 $_ip_grn up"
ifconfig br0 $_ip_grn up

echo "
# --------------------------------------------------- 
# 4. create bridge br1 & allocate IP
# ---------------------------------------------------
"
echo "brctl addbr br1"
brctl addbr br1
echo "brctl addif br1 $_nic_org"
brctl addif br1 $_nic_org

echo "ifconfig br1 $_ip_org up"
ifconfig br1 $_ip_org up

echo "
# --------------------------------------------------- 
# 5. configure red interface & apply nat rules
# ---------------------------------------------------
"
echo "ifconfig $_nic_red $_ip_red up"
ifconfig $_nic_red $_ip_red up

echo "ip route del default"
ip route del default
echo "ip route add default via $_ip_gw"
ip route add default via $_ip_gw

echo "
# --------------------------------------------------- 
# 6. enable ip forwarding
# ---------------------------------------------------
"
echo "echo 1 > /proc/sys/net/ipv4/ip_forward"
echo 1 > /proc/sys/net/ipv4/ip_forward

#iptables -A FORWARD -i br0 -o $_nic_red -s $_cidr_grn -m conntrack --ctstate NEW -j ACCEPT
#iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
#iptables -t nat -F POSTROUTING
#iptables -t nat -A POSTROUTING -o $_nic_red -j MASQUERADE

echo "
################################################################################
#
#   End User Data Action
#
################################################################################
"

EOF
