#!/bin/bash

#METHOD_LIST[0]="prepare"
METHOD_LIST[1]="install_base"
METHOD_LIST[2]="install_keystone"
METHOD_LIST[3]="install_glance"
METHOD_LIST[4]="install_nova"
METHOD_LIST[5]="install_neutron"
METHOD_LIST[6]="install_horizon"
METHOD_LIST[7]="install_heat"
METHOD_LIST[8]="install_rsyslog"

usage() {
  echo "Usage: $0 [MODE]"
  echo "   ex) $0 [manual/auto]"
  exit 0
}

if [ -z $1 ]; then
 usage
else
 mode=$1 
fi

#prepare() {
#  ./00_1_prepare_networking.sh
#  ./00_2_prepare_repository.sh
#}

install_base() {
  ./01_1_install_database.sh
  ./01_2_install_msgQ.sh
  ./01_3_install_ntp.sh
}

install_rsyslog() {
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

install_ceilometer() {
  ./09_1_ceilometer_install_controller_mongodb.sh
  ./09_2_ceilometer_install_controller.sh
  ./09_3_ceilometer_install_compute.sh
  ./09_4_ceilometer_install_image.sh
}

check_continue() {
  PKG_NAME=$1
  echo "Install $PKG_NAME? (Y/N/Q) "
  read line
}

install() {
  method=$1

  mkdir -p log
  eval "$method" 2>&1 | tee -a log/$method.log
}

check_and_install() {
  method=$1

  check_continue $method
  if [ "$line" == "Y" ] ||  [ "$line" == "y" ]; then
    install $method
  elif [ "$line" == "N" ] ||  [ "$line" == "n" ]; then
    echo "*** SKIP INSTALLING $method"
  elif [ "$line" == "Q" ] ||  [ "$line" == "q" ]; then
    echo "*** STOP INSTALLATION"
    exit 0
  else
    echo ""
    printf "%-100s\n" "------------------------------------------------------------------------"
    echo "*** STOP INSTALLATION"
    printf "%-100s\n" "------------------------------------------------------------------------"
    echo ""
    exit 0
  fi
}

run() {
  mode=$1

  for idx in ${!METHOD_LIST[@]}; do
    printf "%d\n" $idx
    method=${METHOD_LIST[$idx]}
    printf "%s\n" $method
    printf "%-100s\n" "------------------------------------------------------------------------"
    printf "===     RUN %-56s ===\n" $method
    printf "%-100s\n" "------------------------------------------------------------------------"

    if [ "$mode" == "manual" ] ; then
      check_and_install $method
    else 
      install $method
    fi

  done
  printf "%-100s\n" "------------------------------------------------------------------------"
}

run $mode
