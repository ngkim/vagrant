설치 순서

  1. 네트워킹 구성

    cd 01_init_onebox
    ./00_1_prepare_networking.sh  
    cd ../

  2. repository 구성

    cd 01_init_onebox
    ./00_2_prepare_repository.sh	
    cd ../

  3. 설치
    ./000_quick_install.sh


TODO
- need to show summary on important information before start installation
- INSTALL에서 verify시에 에러가 확인되면 설치 프로세스를 멈추도록 
- 예) service 동작 안함, endpoint 연결 안됨
- database 생성 및 로그인 가능성 확인
	mysql -unova -pnova nova -e "show tables"
	if [ $? -ne 0 ]; then
	fi 


