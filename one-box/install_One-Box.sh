#!/bin/bash

apt-get install -y ntp git

ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
service ntp restart

