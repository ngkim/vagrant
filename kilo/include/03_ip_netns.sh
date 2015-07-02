create_netns() {
  local NS_NAME=$1

  cmd="ip netns add $NS_NAME"
  run_commands $cmd
}

remove_netns() {
  local NS_NAME=$1

  cmd="ip netns delete $NS_NAME"
  run_commands $cmd
}

ifconfig_netns() {
  local NS_NAME=$1
  local DEV=$2
  local IP_ADDR=$3

  cmd="ip netns exec $NS_NAME ifconfig $DEV $IP_ADDR"
  run_commands $cmd
}

ip_route_add_default_netns() {
  local NS_NAME=$1
  local GW_ADDR=$2

  cmd="ip netns exec $NS_NAME ip route add default via $GW_ADDR"
  run_commands $cmd
}

ip_route_del_default_netns() {
  local NS_NAME=$1

  cmd="ip netns exec $NS_NAME ip route del default"
  run_commands $cmd
}

ip_route_add_netns() {
  local NS_NAME=$1
  local DST_NET=$2
  local NEXT_HOP=$3

  cmd="ip netns exec $NS_NAME ip route add $DST_NET via $NEXT_HOP"
  run_commands $cmd
}

ip_route_del_netns() {
  local NS_NAME=$1
  local DST_NET=$2
  local NEXT_HOP=$3

  cmd="ip netns exec $NS_NAME ip route delete $DST_NET via $NEXT_HOP"
  run_commands $cmd
}

show_route_netns() {
  local NS_NAME=$1

  cmd="ip netns exec $NS_NAME route -n"
  run_commands $cmd
}

ping_netns() {
  local NS_NAME=$1
  local DST_IP=$2
  local OPTS=${@:3:$#}

  cmd="ip netns exec $NS_NAME ping $DST_IP $OPTS"
  run_commands $cmd
}

iperf_tcp_server_netns() {
  local NS_NAME=$1
  local IPERF_LOG=$2

  if [ -z $IPERF_LOG ]; then
    cmd="ip netns exec $NS_NAME iperf -s -i 1"
  else
    cmd="ip netns exec $NS_NAME iperf -s -i 1 &> $IPERF_LOG &"
  fi
  run_commands_no_ret $cmd
}

iperf_tcp_client_netns() {
  local NS_NAME=$1
  local DST_IP=$2
  local OPTS=${@:3:$#}

  cmd="ip netns exec $NS_NAME iperf -c $DST_IP -i 1 $OPTS"
  run_commands $cmd
}

tcpdump_netns() {
  local NS_NAME=$1
  local DEV=$2
  local OPTS=${@:3:$#}

  cmd="ip netns exec $NS_NAME tcpdump -i $DEV -ne -l $OPTS"
  run_commands $cmd
}
