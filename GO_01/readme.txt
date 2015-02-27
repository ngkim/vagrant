Pattern 04: 

  1) NODES
     - Cloud Node (1): OpenStack All-in-one 
                       . mgmt - MGMT (1)
                       . ext  - MGMT (2)
                       . api  - MGMT (3)
                       
                       . guest- AGGR (1)
                       . lan  - AGGR (2)
                       . wan  - AGGR (5) 
                       
     - Host Node  (4): Customer 
                       . green  - ACCS (1)
                       . mgmt   - MGMT (4)
                       
                       Server Farm
                       . orange - STOR (1)
                       . mgmt   - MGMT (5)
                       
                       Public (RED)
                       . red    - CORE (1)
                       . mgmt   - MGMT (6)
                       
                       Orchestrator
                       . mgmt   - MGMT (7)
       
  2) SWITCHES
     - MGMT SW: 8 interfaces (1 vlan)
                - 1 NAT
                - 7 internal networks 
                - NORMAL
                
     - ACCS SW: 8 interfaces (1 vlan)
                - 1 NAT
                - 7 internal networks 
                - NORMAL
                  . eth1 - AGGR (3) - Trunk VLAN 11
                  . eth2 - Customer (green, 1) - Access VLAN 11
                
                  EXT_GROUPS[1]="push_vlan:0x8100,set_vlan_vid:11,output:1"
                  EXT_GROUPS[2]="strip_vlan,output:2"
                  
                  FLOW_RULES[1]="in_port=1,dl_vlan=11 group=2"
                  FLOW_RULES[2]="in_port=2 group=1"
                  
                  
     - STOR SW: 8 interfaces (1 vlan)
                - 1 NAT
                - 7 internal networks 
                - NORMAL
                  . eth1 - AGGR (4) - Trunk VLAN 10
                  . eth2 - Server Farm (orange, 1) - Access VLAN 10
                  
                  EXT_GROUPS[1]="push_vlan:0x8100,set_vlan_vid:10,output:1"
                  EXT_GROUPS[2]="strip_vlan,output:2"
                  
                  FLOW_RULES[1]="in_port=1,dl_vlan=10 group=2"
                  FLOW_RULES[2]="in_port=2 group=1"
                  
                
     - CORE SW: 8 interfaces (1 vlan)
                - 1 NAT
                - 7 internal networks 
                - FLOW_RULE
                  . eth1 - AGGR (6) - Trunk VLAN 10
                  . eth2 - STOR (orange, 1) - Access VLAN 10
                  
                  EXT_GROUPS[1]="push_vlan:0x8100,set_vlan_vid:10,output:1"
                  EXT_GROUPS[2]="strip_vlan,output:2"
                  
                  FLOW_RULES[1]="in_port=1,dl_vlan=10 group=2"
                  FLOW_RULES[2]="in_port=2 group=1"
                  
     - AGGR SW: 7 interfaces 
                - 1 NAT
                - 7 internal networks
                  
                  . eth1: GUEST
                       * 통신할 대상이 없으므로 Flow Rule 구성 없음
                  
                  . eth2: LAN - All-in-one (lan, 5)
                  . eth3: LAN - ACCS SW (1)
                  . eth4: LAN - STOR SW (orange, 1)
                  
                    * Customer -> All-in-one (VLAN 11) inport=3,vlan=11 group=2
                    * ServerF  -> All-in-one (VLAN 10) inport=4,vlan=10 group=2
                    * All-one  -> ACCS SW    (VLAN 11) inport=2,vlan=11 group=3
                    * All-one  -> STOR SW    (VLAN 10) inport=2,vlan=10 group=4
                  
                  . eth5: WAN - All-in-one (wan, 6)
                  . eth6: WAN - CORE SW (red, 1)
                    * All-in-one -> Public     (VLAN 10) inport=5,vlan=10 group=6
                    * Public     -> All-in-one (VLAN 10) inport=6,vlan=10 group=5
                    
                  . eth7 - bridged to - em1 of host node