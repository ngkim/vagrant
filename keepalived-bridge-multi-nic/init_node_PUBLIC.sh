#!/bin/bash

sudo ifconfig eth1 10.15.7.254/24 up	

echo "sudo apt-get update > /dev/null"
sudo apt-get update > /dev/null
echo "sudo apt-get install -y language-pack-en language-pack-ko > /dev/null"
sudo apt-get install -y language-pack-en language-pack-ko > /dev/null
echo "sudo apt-get install -y iperf"
sudo apt-get install -y iperf

sudo route add -net 172.16.10.0 netmask 255.255.255.0 gw 10.15.7.100 dev eth1
