INSTALL에서 verify시에 에러가 확인되면 설치 프로세스를 멈추도록 
- 예) service 동작 안함, endpoint 연결 안됨

- database 생성 및 로그인 가능성 확인
	mysql -unova -pnova nova -e "show tables"
	if [ $? -ne 0 ]; then
	fi 
-