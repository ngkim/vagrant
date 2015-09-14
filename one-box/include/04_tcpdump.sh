run_tcpdump() {
  local DEV=$1
  local OPTS=${@:2:$#}

  cmd="tcpdump -i $DEV -ne -l $OPTS"
  run_commands $cmd
}
