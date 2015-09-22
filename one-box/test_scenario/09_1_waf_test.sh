#!/bin/bash

source "./00_check_config.sh"

NS=`ip netns | grep qrouter`
WAF_IP="192.168.10.38"
DEBUG=1

debug_msg() {
  msg="$*"
  if [ ! -z $DEBUG ]; then 
    print_msg "\n$msg"
  fi
}

get_session_id() {
  debug_msg "${FUNCNAME}: request"
  local RET=`ip netns exec $NS curl --insecure -H \"Expect:\" -vX POST https://${WAF_IP}/webapi/auth -d 'id=admin&password=wafpenta!23' 2>&1 | awk '/WP_SESSID/{print \$3}'`
  debug_msg "${FUNCNAME}: $RET"

  KEY=${RET:0:36}
}


waf_get_call() {
  URL=$1
  local cmd="ip netns exec $NS curl --insecure -H "Content-Type:application/x-www-form-urlencoded" -b $KEY -vX GET $URL 2>/dev/null"
  run_commands_return $cmd
}

waf_put_call() {
  ip netns exec $NS \
	curl --insecure \
		-b $KEY \
		-H "Content-Type:application/x-www-form-urlencoded" \
		-d '{"management_route":[{"nic":"eth0","gateway":"192.168.10.39","netmask":"0.0.0.0","dest_ip":"0.0.0.0"},{"nic":"eth0","gateway":"0.0.0.0","netmask":"255.255.255.0","dest_ip":"192.168.10.0"}]}' -vX PUT https://${WAF_IP}/webapi/conf/management_route 2> /dev/null
}

show_interfaces() {
  waf_get_call https://${WAF_IP}/webapi/conf/network_interface
  JSON=`echo $RET | tr -d '\n'` 
  echo $JSON | json_reformat
}

show_management_route() {
  waf_get_call https://${WAF_IP}/webapi/conf/management_route
  echo $RET | json_reformat
}

show_traffic() {
  waf_get_call https://${WAF_IP}/webapi/statistics/system/traffic?stime=2015-09-08+01%3a24%3a55&etime=2015-09-08+01%3a29%3a55
  #echo $RET | json_reformat
  echo $RET
  
}

show_cpu() {
  local URL="https://${WAF_IP}/webapi/statistics/system/cpu_mem?stime=2015-09-08+01%3a24%3a55&etime=2015-09-08+01%3a29%3a55"
  debug_msg "${FUNCNAME}: call $URL"

  ip netns exec $NS curl --insecure -H \"Content-Type:application/x-www-form-urlencoded\" -b $KEY -vX GET $URL 2>/dev/null
  debug_msg "${FUNCNAME}: done"
}

get_session_id
#show_interfaces
#show_management_route
#show_cpu
#show_traffic
#echo ""

#waf_put_call 

show_management_route

#waf_get_call https://192.168.10.9/webapi/conf/management_route
