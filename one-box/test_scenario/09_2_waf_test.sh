KEY="WP_SESSID=bp78b7047h0mss37g1qbe9vnk5"

WAF_IP=192.168.10.11


waf_get_key() {
  curl --insecure -H "Expect:" -vX POST https://$WAF_IP/webapi/auth -d 'id=admin&password=wafpenta!23' | grep WP_SESSID
}

waf_get_call() {
  URL=$1
  curl --insecure -H "Content-Type:application/x-www-form-urlencoded" -b $KEY -vX GET $URL
}

waf_put_call() {
	curl --insecure \
		-b $KEY \
		-H "Content-Type:application/x-www-form-urlencoded" \
		-d '{"management_route":[{"nic":"eth0","gateway":"192.168.10.10","netmask":"255.255.255.255","dest_ip":"211.224.204.143"}]}' \
		-vX PUT https://$WAF_IP/webapi/conf/management_route
}

#waf_get_key
#send_command_to_waf https://192.168.10.9/webapi/conf/network_interface
waf_get_call https://$WAF_IP/webapi/conf/management_route

echo ""
echo ""
echo ""
echo ""
echo ""

#waf_put_call 

echo ""
echo ""
echo ""
echo ""
echo ""

#waf_get_call https://$WAF_IP/webapi/conf/management_route

