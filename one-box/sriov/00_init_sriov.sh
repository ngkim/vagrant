#!/bin/bash -x

rmmod ixgbe
modprobe ixgbe max_vfs=2

sleep 2

lspci|grep Ether



