#!/bin/bash

./00_prepare_networking.sh

./00_prepare_repository.sh

./01_install_database.sh

./01_install_msgQ.sh

./01_install_ntp.sh

./02_install_keystone.sh

./03_install_keystone_api_endpoint.sh

./03_verify_keystone.sh

./04_glance_install.sh

./04_glance_verify.sh

./05_1_nova_install_controller.sh

#./05_2_nova_install_compute.sh