#!/bin/bash

set -o errexit
#set -o xtrace

echo "
    ############################################################################
        오픈스택을 설치하기 위해 미리 수행되어야 하는 사항
    ############################################################################
    - IPMI 설정
    - 
    - 오픈스텍 계정 생성 : openstack/ohhberry3333
    - root 패스워드 설정
	§ ubuntu@ubuntu:~$ sudo passwd root
	§ Enter New UNIX Password :  ohhberry3333
	§ Retype New Nunix password : ohhberry3333

    #
    # vagrant를 이용한 설치에서는 아래사항 불필요
        - 우분투 Firewall 해제(이건 나중에 보안심의 이슈가 될 수 있슴)
		§ sudo ufw disable
	    - openssh 서버 설치
		§ sudo apt-get install -y openssh-server
	    - root 권한으로 외부에서 ssh 접속 허용 설정(우분투 12.04인 경우 불필요)
		  /etc/ssh/sshd_config 파일의 PermitRootLogin 설정값을? no -> yes로 변경한다.
		  service ssh restart
"

_interactive_mode=true

source ./common_util.sh

#------------------------------------------------------------------------------
#    openstack install topology 설정에 따른 global_env 설정
#------------------------------------------------------------------------------
source ./01allinone_topology_variable_setting.sh
    openstack_install_allinnode_env_for_vagrant
    topology_check
    ask_continue_stop

echo '
--------------------------------------------------------------------------------
    서버 네트워크 환경 설정
        all_in_one_hosts_info_setting
        all_in_one_NIC_setting
--------------------------------------------------------------------------------'

ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
    source ./02allinone_network_setting.sh
        all_in_one_hosts_info_setting
                
        #all_in_one_NIC_setting_for_production -> 추후에 정리해야 함.
        all_in_one_NIC_setting_for_vagrant    
        
fi

echo '
--------------------------------------------------------------------------------
    allinone_global_variable_setting 설정
--------------------------------------------------------------------------------'

source ./03allinone_global_variable_setting.sh

echo '
--------------------------------------------------------------------------------
    서버 환경 설정
        server_syscontrol_change
        timezone_setting
        repository_setting
        install_base_utils
--------------------------------------------------------------------------------'

ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
    source ./04host_base_setting.sh
        server_syscontrol_change
        timezone_setting
        repository_setting
        install_base_utils
fi



echo '
################################################################################
    controller 설치용 쉘 실행 -> controller.sh
################################################################################
'

echo '
--------------------------------------------------------------------------------
    controller 서버에 mysql 설치
    LJG: 나중에 이중화 & 백업 고려해야 함
--------------------------------------------------------------------------------'
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
    source ./05ctrl_mysql_install.sh
        ctrl_mysql_install
fi

echo '
--------------------------------------------------------------------------------
    controller 서버에 keystone 설치
--------------------------------------------------------------------------------'

ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
    export OS_SERVICE_TOKEN=$SERVICE_TOKEN
    export OS_SERVICE_ENDPOINT=http://${KEYSTONE_ENDPOINT}:35357/v2.0/

    unset OS_TENANT_NAME
    unset OS_USERNAME
    unset OS_PASSWORD
    unset OS_AUTH_URL
    unset OS_NO_CACHE

    source ./06ctrl_keystone_install.sh
        ctrl_keystone_install
        ctrl_keystone_config
        ask_continue_stop
        ctrl_keystone_base_user_env_create
        ask_continue_stop
        ctrl_keystone_service_create
        ctrl_keystone_service_endpoint_create
        ctrl_keystone_service_account_role_create

    unset OS_SERVICE_TOKEN
    unset OS_SERVICE_ENDPOINT

fi

cat > ~/openstack_rc <<EOF
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$PASSWORD
export OS_AUTH_URL=http://${KEYSTONE_ENDPOINT}:5000/v2.0/
export OS_NO_CACHE=1
export OS_VOLUME_API_VERSION=2
EOF

cat ~/openstack_rc
source ~/openstack_rc

echo '
--------------------------------------------------------------------------------
    controller 서버에 glance 설치
--------------------------------------------------------------------------------'
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
    source ./07ctrl_glance_install.sh
        ctrl_glance_install
        ctrl_glance_db_create
        ctrl_glance_api_registry_configure
        ctrl_glance_restart
        ctrl_glance_demo_image_create
fi


echo '
--------------------------------------------------------------------------------
    controller 서버에 cinder 설치
--------------------------------------------------------------------------------'
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
    source ./08ctrl_cinder_install.sh
        ctrl_cinder_install
        ctrl_cinder_db_create
        ctrl_cinder_configure
        ctrl_cinder_restart
fi

echo '
--------------------------------------------------------------------------------
    controller 서버에 horizon 설치
--------------------------------------------------------------------------------'
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
	source ./09ctrl_horizon_install.sh
	    ctrl_horizon_install
	    ask_continue_stop
	    ctrl_horizon_configure
	    ask_continue_stop
	    ctrl_apache_configure_restart
fi

echo '
--------------------------------------------------------------------------------
    controller 서버에 ovs 설치
--------------------------------------------------------------------------------'
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
    source ./10ctrl_ovs_install.sh
    	openvswitch_install
    	ask_continue_stop
    	openvswitch_execute
fi

echo '
--------------------------------------------------------------------------------
    controller 서버에 neutron(server, plugin) 설치
--------------------------------------------------------------------------------'
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
    source ./11ctrl_neutron_install.sh
        ctrl_neutron_server_and_plugin_install
        ask_continue_stop
        ctrl_neutron_db_create
        ask_continue_stop
        ctrl_neutron_server_configure
        ask_continue_stop
        ctrl_neutron_plugin_ml2_configure
        ask_continue_stop
        ctrl_neutron_l3_agent_config
        ask_continue_stop
        ctrl_neutron_dhcp_agent_config
        ask_continue_stop
        ctrl_neutron_metadata_agent_config
        ask_continue_stop
        ctrl_neutron_sudoers_append
        ask_continue_stop
        ctrl_neutron_server_restart
        ask_continue_stop
fi

echo '
--------------------------------------------------------------------------------
    controller 서버에 nova 설치
--------------------------------------------------------------------------------'
ask_proceed_skip _answer
if [ "$_answer" = "p" ]; then
    source ./12ctrl_nova_install.sh
        ctrl_nova_install
        ctrl_nova_db_create
        ctrl_nova_configure
        
        compute_nova_install
        compute_nova_compute_configure
        
        ctrl_nova_restart
fi



echo '
--------------------------------------------------------------------------------
    controller 서버에 rsyslog 설정 & 재시작
--------------------------------------------------------------------------------'

echo "\$ModLoad imudp" >> $RSYSLOG_CONF
echo "\$UDPServerRun 5140" >> $RSYSLOG_CONF
echo "\$ModLoad imtcp" >> $RSYSLOG_CONF
echo "\$InputTCPServerRun 5140" >> $RSYSLOG_CONF
restart rsyslog

