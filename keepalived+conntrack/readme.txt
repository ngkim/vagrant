keepalived + conntrack 
- Priority가 높은 VRRP instance가 MASTER가 된다.
- nopreempt옵션을 사용하면 우선순위가 높은 master가 active되어도 서비스를 하던 노드가 계속 서비스한다.

* reference
  - http://backreference.org/2013/04/03/firewall-ha-with-conntrackd-and-keepalived/
  - Highly Available (HA) setting based on a simple Primary/Backup configuration
    . http://conntrack-tools.netfilter.org/testcase.html
  - Note on using VRRP with Virtual MAC address
    . http://fossies.org/linux/keepalived/doc/NOTE_vrrp_vmac.txt
  - The conntrack-tools user manual
    . http://conntrack-tools.netfilter.org/manual.html
  - keepalived configuration guide
    . http://linux.die.net/man/5/keepalived.conf
