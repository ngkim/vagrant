#!/bin/bash

sudo ifconfig eth1 up
sudo ifconfig eth2 up
sudo apt-get -y update
sudo apt-get install -y git