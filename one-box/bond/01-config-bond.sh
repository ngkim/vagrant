#!/bin/bash -x

TESTIP="192.168.254.11/24"
PHYS_DEV="eth1"

# virtual ethernet pair 구성
# int-act-br <-- --> int-act-bond
# int-stb-br <-- --> int-stb-bond
ip link add int-act-br type veth peer name int-act-bond
ip link add int-stb-br type veth peer name int-stb-bond
ifconfig int-act-br 0.0.0.0 up
ifconfig int-act-bond 0.0.0.0 up
ifconfig int-stb-br 0.0.0.0 up
ifconfig int-stb-bond 0.0.0.0 up

# bonding bridge 구성
brctl addbr br-bond
ifconfig br-bond up

# bonding bridge에 물리 NIC 연결
ifconfig $PHYS_DEV up
brctl addif br-bond $PHYS_DEV

# internet bridge 구성
brctl addbr br-internet
ifconfig br-internet up

# wan namespace 구성
ip netns add wan

# wan namespace에  active 링크 연결
ip link set int-act-br netns wan

# internet bridge에 standby 링크 연결
brctl addif br-internet int-stb-br

# bonding 인터페이스 구성
modprobe bonding
ifconfig bond0 up
echo int-act-bond > /sys/class/net/bond0/bonding/primary
ifenslave bond0 int-act-bond int-stb-bond
# bonding bridge에 bonding 인터페이스 연결
brctl addif br-bond bond0

# wan namespace에 IP 할당
ip netns exec wan ifconfig int-act-br ${TEST_IP} up

# internet bridge에 IP 할당
ifconfig br-internet ${TEST_IP} up

