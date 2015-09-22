#!/bin/bash

source "./00_check_config.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

source "$WORK_HOME/include/provider_net_util.sh"

red() {
  #==================================================================
  print_title "PROVIDER_NET: RED"
  #==================================================================
  create_flat_net $RED_NET $RED_PHYSNET
  create_provider_subnet   $RED_NET $RED_SBNET $RED_NETWORK_CIDR
}

green() {
  #==================================================================
  print_title "PROVIDER_NET: GREEN"
  #==================================================================
  create_flat_net     $GRN_NET $GRN_PHYSNET
  create_provider_subnet  $GRN_NET $GRN_SBNET     $GRN_NETWORK_CIDR
}

orange() {
  #==================================================================
  print_title "PROVIDER_NET: ORANGE"
  #==================================================================
  create_flat_net     $ORG_NET $ORG_PHYSNET
  create_provider_subnet  $ORG_NET $ORG_SBNET     $ORG_NETWORK_CIDR
}

red
green
orange


