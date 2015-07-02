iterate_array() {
  local -a _ARR=("${!1}")

  for idx in "${!_ARR[@]}"; do 
    val=${_ARR[$idx]}

    printf "%s\t%s\n" "$idx" "$val"
  done
  echo 
}

iterate_array_cmd() {
  local -a _ARR=("${!1}")
  local CMD=$2
  local OPTS=${@:3:$#}

  for idx in "${!_ARR[@]}"; do 
    local val=${_ARR[$idx]}
  
    echo -e ${green}${CMD} $val ${normal}
    eval "$CMD $OPTS"
  done
  echo 
}
