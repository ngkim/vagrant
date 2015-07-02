delete_vm() {
  VM_NAME=$1

  cmd="nova list | awk '/'$VM_NAME'/{print \$2}'"
  run_commands $cmd
  for vm in $RET; do
    if [ ! -z $vm ]; then
      cmd="nova delete $vm"
      run_commands $cmd
    fi
  done
  
}
