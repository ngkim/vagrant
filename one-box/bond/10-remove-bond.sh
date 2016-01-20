#!/bin/bash -x

brctl delif br-bond eth1
brctl delif br-bond bond0
ifconfig br-bond down
brctl delbr br-bond

ovs-vsctl del-port br-wan int-act-br
ovs-vsctl del-br br-wan


brctl delif br-internet int-stb-br
ifconfig br-internet down
brctl delbr br-internet

ip link delete dev int-act-br
ip link delete dev int-stb-br

ip netns del wan
ifconfig bond0 down
