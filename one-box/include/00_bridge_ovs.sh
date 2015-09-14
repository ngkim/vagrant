create_bridge() {
  local BR_NAME=$1

  cmd="ovs-vsctl add-br $BR_NAME"
  run_commands $cmd
}

delete_bridge() {
  local BR_NAME=$1

  cmd="ovs-vsctl del-br $BR_NAME"
  run_commands $cmd
}

add_interface() {
  local BR_NAME=$1
  local DEV=$2

  cmd="ovs-vsctl add-port $BR_NAME $DEV"
  run_commands $cmd
}

delete_interface() {
  local BR_NAME=$1
  local DEV=$2

  cmd="ovs-vsctl del-port $BR_NAME $DEV"
  run_commands $cmd
}

activate_interface() {
  local BR_NAME=$1

  cmd="ifconfig $BR_NAME up"
  run_commands $cmd
}

list_interfaces() {
  local BR_NAME=$1

  cmd="ovs-vsctl list-ports $BR_NAME"
  run_commands $cmd
}

list_bridges() {
  cmd="ovs-vsctl list-br"
  run_commands $cmd
}

setup_bridge() {
  local BR_NAME=$1
  declare -a ITF=("${!2}")

  create_bridge $BR_NAME

  for (( i = 0 ; i < ${#ITF[@]} ; i++ )) do
        DEV=${ITF[$i]}
        add_interface $BR_NAME $DEV
  done

  activate_interface $BR_NAME
  list_interfaces $BR_NAME
}

destroy_bridge() {
  local BR_NAME=$1
  declare -a ITF=("${!2}")

  for (( i = 0 ; i < ${#ITF[@]} ; i++ )) do
        DEV=${ITF[$i]}
        delete_interface $BR_NAME $DEV
  done

  delete_bridge $BR_NAME

  list_bridges
}

clear_bridge() {
  local BR_NAME=$1
  
  list_interfaces $BR_NAME
  for port in $RET; do
    delete_interface $BR_NAME $port
  done

  delete_bridge $BR_NAME
}


