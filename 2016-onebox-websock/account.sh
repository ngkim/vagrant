#!/bin/bash -x

adduser onebox
adduser onebox sudo
passwd -d vagrant

echo "1) update hostname file in /etc/hostname"
echo "2) add hostname in /etc/hosts"
echo "3) run hostname command"

