#!/bin/bash

sudo sed 's@us.archive.ubuntu.com@ftp.daum.net@' -i /etc/apt/sources.list
sudo sed 's@archive.ubuntu.com@ftp.daum.net@' -i /etc/apt/sources.list
sudo sed 's@security.ubuntu.com@ftp.daum.net@' -i /etc/apt/sources.list 
sudo apt-get update

sudo ifconfig eth1 10.0.0.102/24 up
sudo ifconfig eth2 up
sudo ifconfig eth3 up
