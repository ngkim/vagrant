###############################################################################
    하나의 서버에 icehouse 콤포넌트를 모두 설치하기 위한 스크립트임
###############################################################################

- 설치를 위해 원격접속을 위한 준비사항         
    - 가능하면 IPMI 설정하여 웹콘솔로 접속
        HP의 경우 컴퓨터 부팅때 F8로 ILO 화면에서 설정
        사용예) https://221.145.180.108/ -> 신규 서버 ILO 웹콘솔
                웹콘솔에 로그인하여 리모트콘솔로 접속하여 설치가능
    - 리모트 콘솔이나 KVM 콘솔에서 수행해야 할 작업
        - root 패스워드 설정
		    ubuntu@ubuntu:~$ sudo passwd root
			Enter New UNIX Password :  ohhberry3333  
			Reype New Nunix password : ohhberry3333
		- 우분투 Firewall 해제(이건 나중에 보안심의 이슈가 될 수 있슴)
			sudo ufw disable
		- 우분투 12.04인 경우 리포지터리 추가
			vi /etc/apt/sources.list 변경
			서버를 모두 ftp.daum.net으로 변경
			ex) vi에서 ":%s/us.archive.ubuntu.com/ftp.daum.net/g" 실행
			apt-get update
			apt-get -y install python-software-properties
			add-apt-repositiory -y cloud-archive:icehouse
		- openssh 서버 설치
			sudo apt-get install -y openssh-server
		- root 권한으로 외부에서 ssh 접속 허용 설정(우분투 12.04인 경우 불필요)
			/etc/ssh/sshd_config 파일의 PermitRootLogin 설정값을? no -> yes로 변경한다.
            service ssh restart 로 sshd를 새로운 설정이 적용되도록 restart한다.
    
    - 우분투 버전(12.04/14.04)에 따라 신경써야할 내용들
        - 12.04 서버의 레포지토리 사이트 수정 필요
            /etc/apt/sources.lists 에서 서버를 모두 ftp.daum.net으로 변경
            ex) vi에서 ":%s/us.archive.ubuntu.com/ftp.daum.net/g" 실행
    
        - 12.04 서버에 설치할 때는 cloud-archive:icehouse 레포지토리 추가 필요
            apt-get update
            apt-get -y install python-software-properties
    		add-apt-repositiory -y cloud-archive:icehouse
    		        
        - 12.04는 NIC 식별이 eth0, eth1, eth2 ....순서
             10G NIC도 eth로 식별됨    
        - 14.04는 NIC 식별이 em1, em2, em3, em4 ....순서
             10G NIC은 p1p1, p1p2로 식별됨            

- 함수는 반드시 수행한 내역에 대한 확인 내용 포함    
    
- LJG: 모든 구성파일에 로그를 감시하기 위해 다음과 같은 항목은 필수
    verbose = True
    debug = True
    
    use_syslog = True
    syslog_log_facility = LOG_LOCAL0


###############################################################################    
- 프로그램 설명
###############################################################################

allinone_icehouse_install.sh
    :: 프로그램 설치 메인 스크립트


allinone_topology_variable_setting.sh
    :: openstack install topology 설정에 따른 variable 설정
        openstack_install_allinnode_env
        topology_check        

allinone_global_variable_setting.sh
    :: 오픈스택 설치시 참조변수들 설정
        오픈스택 계정변수 설정
        MySQL 변수 설정
        오픈스택 서비스 계정 설정
        오픈스택 호스트 및 이미지 변수 설정        
        오픈스택 콤포넌트 구성정보 파일 정보 설정 
        오픈스택 open-vswitch 설정 변수설정        
        
allinone_network_setting.sh
    :: icehouse를 설치하기 위해 필요한 서버의 network 기본정보 설정
        openstack_install_allinnode_env
        topology_check
                
host_base_setting.sh
    :: icehouse를 설치하는 서버에서 기본적으로 수행되어야 할 기능 실행
        server_syscontrol_change
        timezone_setting
        repository_setting
        install_base_utils
    
common_utils.sh
    :: icehouse 설치 주요 라이브러리

#
# controller 모듈 설치

ctrl_mysql_install.sh
    :: controller 서버에 mysql 설치(LJG: 나중에 이중화 & 백업 고려해야 함)
        ctrl_mysql_install

ctrl_keystone_install.sh
    :: controller 서버에 keystone 설치
        ctrl_keystone_install
        ctrl_keystone_config        
        ctrl_keystone_base_user_env_create        
        ctrl_keystone_service_create
        ctrl_keystone_service_endpoint_create
        ctrl_keystone_service_account_role_create
        openstack_rc 생성

ctrl_glance_install.sh
    :: controller 서버에 glance 설치
        ctrl_glance_install
        ctrl_glance_db_create
        ctrl_glance_api_registry_configure
        ctrl_glance_restart
        ctrl_glance_demo_image_create    

ctrl_cinder_install.sh
    :: controller 서버에 cinder 설치
        ctrl_cinder_install
        ctrl_cinder_db_create
        ctrl_cinder_configure
        ctrl_cinder_restart
        
    
ctrl_horizon_install.sh
    :: controller 서버에 horizon 설치
        ctrl_horizon_install
        ctrl_horizon_configure
        ctrl_apache_configure_restart

ctrl_ovs_install.sh
    :: controller 서버에 ovs 설치
        openvswitch_install
        openvswitch_execute    

ctrl_neutron_install.sh
    :: controller 서버에 neutron(server, plugin) 설치
        ctrl_neutron_server_and_plugin_install
        ctrl_neutron_db_create
        ctrl_neutron_server_configure
        ctrl_neutron_plugin_ml2_configure
        ctrl_neutron_sudoers_append
        ctrl_neutron_server_restart        
    
ctrl_nova_install.sh
    :: controller 서버에 nova 설치
        ctrl_nova_install
        ctrl_nova_db_create
        ctrl_nova_configure        
        compute_nova_install
        compute_nova_compute_configure        
        ctrl_nova_restart


controller 서버에 rsyslog 설정 & 재시작
