#!/bin/bash

prepare() {
  ./00_1_prepare_networking.sh
  ./00_2_prepare_repository.sh
}

install_base() {
  ./01_1_install_database.sh
  ./01_2_install_msgQ.sh
  ./01_3_install_ntp.sh
  ./01_4_install_rsyslog.sh
}

install_keystone() {
  ./02_1_install_keystone.sh
  ./02_1_install_keystone_api_endpoint.sh
  ./02_2_verify_keystone.sh
}

install_glance() {
  ./04_1_glance_install.sh
  ./04_2_glance_verify.sh
}

install_nova() {
  ./05_1_nova_install_controller.sh
  ./05_1_1_nova_verify_controller.sh
  ./05_2_nova_install_compute.sh
  ./05_3_verify_nova_compute.sh
}

install_neutron() {
  ./06_1_neutron_install_controller.sh
  ./06_1_1_verify_neutron_controller.sh
  ./06_2_neutron_install_network.sh
  ./06_3_neutron_install_compute.sh
  ./06_3_1_verify_neutron_compute.sh
}

install_horizon() {
  ./07_horizon_install.sh
}

install_heat() {
  ./08_heat_install.sh
}

check_continue() {
  PKG_NAME=$1
  echo "Install $PKG_NAME? (Y/N) "
  read line
}

METHOD_LIST="prepare install_base install_keystone install_glance install_nova install_neutron install_horizon install_heat"

run() {
  for method in $METHOD_LIST; do
    check_continue $method
    if [ "$line" == "Y" ] ||  [ "$line" == "y" ]; then
      eval $method
    elif [ "$line" == "N" ] ||  [ "$line" == "n" ]; then
      echo "*** SKIP INSTALLING $method"
    else
      echo ""
      echo ""
      echo ""
      echo ""
      echo ""
      echo "*** STOP INSTALLATION"
      echo ""
      echo ""
      echo ""
      echo ""
      echo ""
      exit 0
    fi
  done

#./09_1_ceilometer_install_controller_mongodb.sh
#./09_2_ceilometer_install_controller.sh
#./09_3_ceilometer_install_compute.sh
#./09_4_ceilometer_install_image.sh
}

run
