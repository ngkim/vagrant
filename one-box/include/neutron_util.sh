
create_port_in_provider_net() {
  local NET_NAME=$1
  local SBNET_NAME=$2
  local _NETWORK_IP=$3

  cmd="neutron net-list | awk '/${NET_NAME}/{print \$2}'"
  run_commands_return $cmd
  local _NET_ID=$RET

  cmd="neutron subnet-list | awk '/${SBNET_NAME}/{print \$2}'"
  run_commands_return $cmd
  local _SBNET_ID=$RET

  cmd="neutron port-list | awk '/${_NETWORK_IP}/{print \$2}'"
  run_commands_return $cmd
  _PORT_ID=$RET

  if [ -z $_PORT_ID ]; then
    #cmd="neutron port-create $_NET_ID --fixed-ip subnet_id=$_SBNET_ID,ip_address=$_NETWORK_IP --port_security_enabled False | awk '/ id/{print \$4}'"
    cmd="neutron port-create $_NET_ID --fixed-ip subnet_id=$_SBNET_ID,ip_address=$_NETWORK_IP | awk '/ id/{print \$4}'"
    run_commands_return $cmd
    _PORT_ID=$RET
  fi

}


