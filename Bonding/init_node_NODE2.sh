#!/bin/bash

sudo apt-get install -y vlan iperf
sudo modprobe 8021q
sudo ifconfig eth2 up
sudo vconfig add eth2 2001
sudo ifconfig eth2.2001 192.168.1.2/24 up
	
