#!/bin/bash

file_name=$1

_nic_wan=$2
_nic_lan_1=$3
_nic_lan_2=$4
_nic_lan_3=$5

_ip_wan=$6
_ip_lan_1=$7
_ip_lan_2=$8
_ip_lan_3=$9

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

apt-get -y update  
apt-get -y install iperf ifstat sysstat bridge-utils

echo "
# --------------------------------------------------- 
# 2. nic activate
# ---------------------------------------------------
"
ifconfig $_nic_wan $_ip_wan up
ifconfig $_nic_lan_1 $_ip_lan_1 up
ifconfig $_nic_lan_2 $_ip_lan_2 up
ifconfig $_nic_lan_2 $_ip_lan_3 up

echo "
# --------------------------------------------------- 
# 3. enable ip_forward
# ---------------------------------------------------
"

echo 1 > /proc/sys/net/ipv4/ip_forward

echo "
# --------------------------------------------------- 
# 4. apply nat rules
# ---------------------------------------------------
"
iptables -t nat -F POSTROUTING
iptables -t nat -A POSTROUTING -o $_nic_wan -j SNAT --to 211.193.42.51

# DNAT Rules
iptables -t nat -A PREROUTING -i $_nic_wan --dst 211.193.42.27 -j DNAT --to 10.10.3.11
iptables -t nat -A PREROUTING -i $_nic_wan --dst 211.193.42.27 -p tcp --dport  1001 -j DNAT --to 10.10.3.11:43315
iptables -t nat -A PREROUTING -i $_nic_wan --dst 211.193.42.27 -p tcp --dport  1002 -j DNAT --to 10.10.3.12:43315
iptables -t nat -A PREROUTING -i $_nic_wan --dst 211.193.42.27 -p tcp --dport  1003 -j DNAT --to 10.10.3.13:43315
iptables -t nat -A PREROUTING -i $_nic_wan --dst 211.193.42.27 -p tcp --dport 43316 -j DNAT --to 10.10.3.12:43315
iptables -t nat -A PREROUTING -i $_nic_wan --dst 211.193.42.27 -p tcp --dport 43317 -j DNAT --to 10.10.3.13:43315
iptables -t nat -A PREROUTING -i $_nic_wan --dst 211.193.42.27 -p tcp --dport 43318 -j DNAT --to 10.10.3.14:43315
iptables -t nat -A PREROUTING -i $_nic_wan --dst 211.193.42.27 -p tcp --dport 43319 -j DNAT --to 10.10.3.15:43315
iptables -t nat -A PREROUTING -i $_nic_wan --dst 211.193.42.27 -p tcp --dport 43320 -j DNAT --to 10.10.3.16:43315
iptables -t nat -A PREROUTING -i $_nic_wan --dst 211.193.42.24 -p tcp --dport 43315 -j DNAT --to 10.10.9.22:43315

echo "
# --------------------------------------------------- 
# 5. routing table entries
# ---------------------------------------------------
"

route add -net 10.10.0.0/24 gw 211.193.42.90 dev $_nic_lan_2
route add -net 10.10.1.0/24 gw 211.193.42.90 dev $_nic_lan_2
route add -net 10.10.2.0/24 gw 211.193.42.90 dev $_nic_lan_2
route add -net 10.10.3.0/24 gw 211.193.42.90 dev $_nic_lan_2
route add -net 10.10.5.0/24 gw 211.193.42.90 dev $_nic_lan_2
route add -net 10.10.6.0/24 gw 211.193.42.90 dev $_nic_lan_2
route add -net 10.10.7.0/24 gw 211.193.42.90 dev $_nic_lan_2
route add -net 10.10.8.0/24 gw 211.193.42.90 dev $_nic_lan_2

route add default gw 211.196.251.153 dev $_nic_wan

echo "
################################################################################
#
#   End User Data Action
#
################################################################################
"

EOF
