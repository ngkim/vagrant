
**********************************************************
*** 0) ext-net.ini 파일수정
*********************************************************
e

**********************************************************
*** 1) 네트워크 생성 
**********************************************************
>> ./03_2_create_provider_net.sh

**********************************************************
*** 2) VM 생성 명령어
***    - 다수의네트워크 인터페이스를 가진 VM을 생성
**********************************************************
>> ./05_nova_boot_ubuntu_multinic.sh

**********************************************************
*** 3) VM 접속용 ssh key 생성
**********************************************************
>> ./04_add_keypair.sh

**********************************************************
*** 4) UBUNTU VM 생성 및 접속 테스트 
**********************************************************
>> nova list
+--------------------------------------+---------+--------+------------+-------------+-----------------------------------------------------------------------------------------------------------------------------------+
| ID                                   | Name    | Status | Task State | Power State | Networks                                                                                                                          |
+--------------------------------------+---------+--------+------------+-------------+-----------------------------------------------------------------------------------------------------------------------------------+
| 163d1333-ee88-4b65-81af-ec99c4a84aee | test_vm | ACTIVE | -          | Running     | global_mgmt_net=192.168.10.3; net_internet=10.0.0.11; net_local=192.168.2.227; net_office=192.168.0.227; net_server=192.168.1.227 |
+--------------------------------------+---------+--------+------------+-------------+-----------------------------------------------------------------------------------------------------------------------------------+

**********************************************************
*** 5) VM 접속명령어
**********************************************************
>> ip netns exec `ip netns | grep qrouter` ssh -i keys/adminkey ubuntu@192.168.10.3
