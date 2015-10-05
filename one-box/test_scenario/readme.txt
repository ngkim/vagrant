* HOW TO CREATE and CONFIG vUTM

0) ext-net.ini 파일확인

1) ./06_1_nova_boot_endian.sh 실행하여 vUTM 생성

2) nova list 명령을 통해 vUTM의 management ip를 얻음
   - vUTM의 ip: 192.168.10.8
+--------------------------------------+------+--------+------------+-------------+-----------------------------------------------------------------------------------------------------------------------------------------+
| ID                                   | Name | Status | Task State | Power State | Networks                                                                                                                                |
+--------------------------------------+------+--------+------------+-------------+-----------------------------------------------------------------------------------------------------------------------------------------+
| 5c03987a-ab44-461a-be7c-94bd52eb5135 | vUTM | ACTIVE | -          | Running     | global_mgmt_net=192.168.10.8; net_internet=211.224.204.227; net_local=192.168.2.227; net_office=192.168.0.227; net_server=192.168.1.227 |
| afc45986-5965-4055-a6a6-0a8168b4d79e | vWAF | ACTIVE | -          | Running     | global_mgmt_net=192.168.10.9; net_local=192.168.2.15; net_server=192.168.1.15                                                           |
+--------------------------------------+------+--------+------------+-------------+-----------------------------------------------------------------------------------------------------------------------------------------+

3) ./10_0_utm_copy_ssh_key.sh 192.168.10.8 qazwsx123
   - 192.168.10.8은 vUTM의 management ip
   - qazwsx123은 vUTM의 root 로그인 password

4) ./10_1_utm_config_ethernet.sh 192.168.10.8 192.168.0.227 192.168.1.227 192.168.2.227 
   - 192.168.10.8
   - 192.168.0.227: Green zone ip
   - 192.168.1.227: Orange zone ip
   - 192.168.2.227: Blue zone ip (local host connectivity)

5) ./10_1_utm_config_uplink.sh

6) ./10_1_utm_config_snat.sh

7) ./10_1_utm_config_dnat.sh

8) ./10_1_utm_config_interzone.sh

9) ./10_1_utm_config_access.sh

00_check_config.sh           03_4_create_flat_net.sh        07_heat_verify.sh          10_1_utm_config_dhcp.sh       11_delete_ext_net.sh         15_nova_delete_cirros.sh
01_create_ext_net.sh         04_add_keypair.sh              08_ceilometer_verify.sh    10_1_utm_config_dnat.sh       12_delete_img.sh             15_nova_delete_ubuntu.sh
02_1_copy_vnf_images.sh      05_nova_boot_cirros.sh         09_1_waf_test.sh           10_1_utm_config_ethernet.sh   13_1_delete_tenant_net.sh    16_1_nova_delete_endian.sh
02_2_register_img.sh         05_nova_boot_ubuntu.sh         09_2_waf_test.sh           10_1_utm_config_interzone.sh  13_2_delete_provider_net.sh  16_2_nova_delete_vWAF.sh
03_1_create_tenant_net.sh    06_1_nova_boot_endian.sh       10_0_utm_copy_ssh_key.exp  10_1_utm_config_snat.sh       13_3_delete_blue_net.sh      ext-net.ini
03_2_create_provider_net.sh  06_2_nova_boot_waf.sh          10_0_utm_copy_ssh_key.sh   10_1_utm_config_uplink.sh     13_4_delete_flat_net.sh      keys
03_3_create_blue_net.sh      06_3_nova_boot_endian_test.sh  10_1_utm_config_access.sh  10_2_vutm_perf.sh             14_delete_keypair.sh         utm_config
 
