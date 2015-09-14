activate_interface() {
  local BR_NAME=$1

  cmd="ifconfig $BR_NAME up"
  run_commands $cmd
}

deactivate_interface() {
  local BR_NAME=$1

  cmd="ifconfig $BR_NAME down"
  run_commands $cmd
}

create_bridge() {
  local BR_NAME=$1

  cmd="brctl addbr $BR_NAME"
  run_commands $cmd
}

delete_bridge() {
  local BR_NAME=$1

  deactivate_interface $BR_NAME

  cmd="brctl delbr $BR_NAME"
  run_commands $cmd
}

add_interface() {
  local BR_NAME=$1
  local DEV=$2

  cmd="brctl addif $BR_NAME $DEV"
  run_commands $cmd
}

delete_interface() {
  local BR_NAME=$1
  local DEV=$2

  cmd="brctl delif $BR_NAME $DEV"
  run_commands $cmd
}

list_interfaces() {
  local BR_NAME=$1

  cmd="brctl show"
  run_commands $cmd
}

list_bridges() {
  cmd="brctl show"
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

