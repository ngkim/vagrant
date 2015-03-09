#!/bin/bash

sysctl -w net.ipv4.conf.all.arp_ignore=1
sysctl -w net.ipv4.conf.all.arp_announce=1
sysctl -w net.ipv4.conf.all.arp_filter=0

sysctl -w net.ipv4.conf.eth1.arp_filter=1
sysctl -w net.ipv4.conf.eth2.arp_filter=1

sysctl -w net.ipv4.conf.vrrp61.arp_filter=0
sysctl -w net.ipv4.conf.vrrp61.accept_local=1
sysctl -w net.ipv4.conf.vrrp61.rp_filter=0

sysctl -w net.ipv4.conf.vrrp62.arp_filter=0
sysctl -w net.ipv4.conf.vrrp62.accept_local=1
sysctl -w net.ipv4.conf.vrrp62.rp_filter=0
