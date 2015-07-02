kill_process() {
  local PID=$1

  cmd="kill $PID"
  run_commands $cmd
}

kill_process_tree() {
  local PID=$1

  for cPID in `pgrep -P $PID`; do
    kill_process $cPID
  done

  kill_process $PID
  
}

# record PID to an array
record_pid() {
  local arr_name=$1
  local SEQ=$2
  local PID=$3

  echo "$SEC PID= $PID"
  eval "${arr_name}[$SEQ]=$PID"
}

export_pid() {
  declare -a PIDs=("${!1}")
  local PID_FILE=$2

  rm -rf $PID_FILE
  for (( i = 0 ; i < ${#PIDs[@]} ; i++ )) do
        _PID=${PIDs[$i]}
        echo $_PID >> $PID_FILE
  done
}


