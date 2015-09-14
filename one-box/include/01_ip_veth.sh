create_veth() {
  local L_DEV=$1
  local R_DEV=$2

  cmd="ip link add $L_DEV type veth peer name $R_DEV"
  run_commands $cmd

  cmd="ifconfig $L_DEV up"
  run_commands $cmd

  cmd="ifconfig $R_DEV up"
  run_commands $cmd
}

delete_veth() {
  local L_DEV=$1
  local R_DEV=$2

  cmd="ip link delete $L_DEV type veth"
  run_commands $cmd
}

set_veth_ns() {
  local DEV=$1
  local NS_NAME=$2

  ip link set $DEV netns $NS_NAME
}


