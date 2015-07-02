create_vlan_interface() {
  local DEV=$1
  local VLAN=$2

  cmd="vconfig add $DEV $VLAN"
  run_commands $cmd
  
  cmd="ifconfig $DEV.$VLAN up"
  run_commands $cmd
}

remove_vlan_interface() {
  local DEV=$1
  local VLAN=$2

  cmd="ifconfig $DEV.$VLAN down"
  run_commands $cmd

  cmd="vconfig rem $DEV.$VLAN"
  run_commands $cmd
}

