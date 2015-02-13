2015-02-13

- VM이 지닌 여러 개의 인터페이스들을 연계하여 failover를 수행하는 것을 확인하기 위해
  vrrp_sync_group을 테스트

- Master에는 br0에 eth1과 eth2가 할당된 상태이고, eth3에 wan이 연결되어 있다.
- Slave에는 br0에 eth1과 eth2가 할당된 상태이고, eth3에 wan이 연결되어 있다.

- Master의 eth1, eth2, eth3중 하나만이라도 죽는다면 Slave쪽으로 절체되는 것을 테스트하려 함

- vrry_sync_group에 VI_WAN과 VI_LAN을 할당
- vrrp_instance의 옵션중 interface와 track_interface의 차이는 무엇인가?
- br0에는 실제로 eth1과 eth2가 연결되어 이들에 대한 상태관리가 필요하다. 
  이를 어떻게 구성하는가? 
