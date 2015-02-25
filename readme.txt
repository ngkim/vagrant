###########################################################################
 Author:  Namgon Kim
 Contact: day10000@gmail.com
###########################################################################

---------------------------------------------------------------------------
# TODO LIST 
---------------------------------------------------------------------------

Pattern 04: 
  1) NODES
     - Cloud Node (1): OpenStack All-in-one 
     - Host Node  (4): Customer 
                       Server Farm
                       Public (RED)
                       Orchestrator
       
  2) SWITCHES
     - MGMT SW: 8 interfaces (1 vlan)                
     - ACCS SW: 8 interfaces (1 vlan)
     - STOR SW: 8 interfaces (1 vlan)
     - CORE SW: 8 interfaces (1 vlan)
     - AGGR SW: 7 interfaces 
                  
- Pattern 03: 
    OpenStack All-in-one (vUTM)
    + Ubuntu VMs (Office, Server Farm) 
    + Open vSwitch with OpenFlow 1.3 (MGMT SW, AGGR SW)
    + Connected to external network through bridged network (em1)

---------------------------------------------------------------------------
# WORKS DONE
---------------------------------------------------------------------------
 
2015-02-24
- Pattern 02 (openstack-mn-1c)
    OpenStack All-in-one (vUTM) + C-node-1 (Office, Server Farm) 
    + Open vSwitch with OpenFlow 1.3 (MGMT SW, AGGR SW)
    + Connected to external network through bridged network (em1)

2015-02-23
- Pattern 01 (openvswitch-of-1.3)
    Open vSwitch with OpenFlow 1.3 (MGMT SW, AGGR SW)
    + Connected to external network through bridged network (em1)

