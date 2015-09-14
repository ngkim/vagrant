
delete_vm() {
  local _VM_NAME=$1

  cmd="nova list | awk '/${_VM_NAME}/{print \$2}'"
  run_commands_return $cmd

  for VM_ID in $RET; do
    if [ ! -z $VM_ID ]; then
      cmd="nova delete $VM_ID"
      run_commands $cmd
    fi
  done
}


