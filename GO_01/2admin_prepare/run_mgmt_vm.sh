#!/bin/bash

# _senario.txt 파일에 있는 내용을 실행한다.

source ./common_env
source ./common_lib

echo "
--------------------------------------------------------------------------------
    8. 8make_global_mgmt_vm.sh
    - admin 계정으로 global_mgmt_network에 연결된 모든 vm에 접속할 수 있는 
      vm을 만들고 외부접속을 위해 floating ip를 할당한다.
       
        - global_mgmt_net에 vm(global_mgmt_vm)을 생성한다.
        - global_mgmt_vm에 floating_ip를 할당한다.
    
--------------------------------------------------------------------------------"

source ./8make_global_mgmt_vm.sh	    
    make_global_mgmt_vm mgmt_vm01 ubuntu-12.04 ssh_pool seocho-az cnode01 ./81global_mgmt_vm_template.sh  
    allocate_floating_ip_to_mgmt_vm mgmt_vm01



echo "
--------------------------------------------------------------------------------
floating-ip 동작확인
    1. ip netns로 floating-ip와 연결된 라우터 확인(ex: global_mgmt_router)
    2. 라우터 내부의 namespace에 floating-ip와 global_mgmt_nic 사이의 NAT 설정정보 확인         
        DNAT       all  --  anywhere             221.145.180.73       to:10.0.0.2
        SNAT       all  --  10.0.0.2             anywhere             to:221.145.180.73
--------------------------------------------------------------------------------
        
	root@controller:~# ip netns
	qrouter-c03adec9-fbd5-4cb8-a770-19d1f9a75040
	qdhcp-53f3c6e1-6646-42aa-ab2a-18dcba91d535
	root@controller:~# ip netns exec qrouter-c03adec9-fbd5-4cb8-a770-19d1f9a75040 iptables -L -t nat
	Chain PREROUTING (policy ACCEPT)
	target     prot opt source               destination         
	neutron-l3-agent-PREROUTING  all  --  anywhere             anywhere            
	
	Chain INPUT (policy ACCEPT)
	target     prot opt source               destination         
	
	Chain OUTPUT (policy ACCEPT)
	target     prot opt source               destination         
	neutron-l3-agent-OUTPUT  all  --  anywhere             anywhere            
	
	Chain POSTROUTING (policy ACCEPT)
	target     prot opt source               destination         
	neutron-l3-agent-POSTROUTING  all  --  anywhere             anywhere            
	neutron-postrouting-bottom  all  --  anywhere             anywhere            
	
	Chain neutron-l3-agent-OUTPUT (1 references)
	target     prot opt source               destination         
	DNAT       all  --  anywhere             221.145.180.73       to:10.0.0.2
	
	Chain neutron-l3-agent-POSTROUTING (1 references)
	target     prot opt source               destination         
	ACCEPT     all  --  anywhere             anywhere             ! ctstate DNAT
	
	Chain neutron-l3-agent-PREROUTING (1 references)
	target     prot opt source               destination         
	REDIRECT   tcp  --  anywhere             169.254.169.254      tcp dpt:http redir ports 9697
	DNAT       all  --  anywhere             221.145.180.73       to:10.0.0.2
	
	Chain neutron-l3-agent-float-snat (1 references)
	target     prot opt source               destination         
	SNAT       all  --  10.0.0.2             anywhere             to:221.145.180.73
	
	Chain neutron-l3-agent-snat (1 references)
	target     prot opt source               destination         
	neutron-l3-agent-float-snat  all  --  anywhere             anywhere            
	SNAT       all  --  10.0.0.0/24          anywhere             to:221.145.180.71
	
	Chain neutron-postrouting-bottom (1 references)
	target     prot opt source               destination         
	neutron-l3-agent-snat  all  --  anywhere             anywhere
"