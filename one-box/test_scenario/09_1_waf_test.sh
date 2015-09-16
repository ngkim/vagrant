#!/bin/bash

source "./00_check_config.sh"

NS="qrouter-fbbba21e-718b-4d68-96cd-cdafd3fed71a"
cmd="ip netns exec $NS curl --insecure -H \"Expect:\" -vX POST https://192.168.10.9/webapi/auth -d 'id=admin&password=wafpenta!23'"
#run_commands_return $cmd
#echo $RET

#echo $SESS_ID
#ip netns exec $NS curl --insecure -H "Expect:" -vX POST https://192.168.10.9/webapi/auth -d 'id=admin&password=wafpenta!23'
#curl --insecure -H "Content-Type:application/x-www-form-urlencoded" -b $KEY -vX GET https://192.168.10.9/webapi/conf/network_interface

KEY="WP_SESSID=0q543t2epghato8nh9tlvpk706"

waf_get_call() {
  URL=$1
  ip netns exec $NS curl --insecure -H "Content-Type:application/x-www-form-urlencoded" -b $KEY -vX GET $URL
}

waf_put_call() {
  ip netns exec $NS \
	curl --insecure \
		-b $KEY \
		-H "Content-Type:application/x-www-form-urlencoded" \
		-d '{"management_route":[{"nic":"eth0","gateway":"192.168.10.10","netmask":"255.255.255.128","dest_ip":"211.224.204.128"}]}' \
		-vX PUT https://192.168.10.9/webapi/conf/management_route
}

#send_command_to_waf https://192.168.10.9/webapi/conf/network_interface
waf_get_call https://192.168.10.9/webapi/conf/management_route

echo ""
echo ""
echo ""
echo ""
echo ""

waf_put_call 

echo ""
echo ""
echo ""
echo ""
echo ""


waf_get_call https://192.168.10.9/webapi/conf/management_route
