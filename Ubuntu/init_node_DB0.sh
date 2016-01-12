#!/bin/bash

#echo "1. DELETE default gw"
#sudo ip route del default
#sudo ip route add default via 10.0.0.254

iptables -F

echo "Done!!!"

