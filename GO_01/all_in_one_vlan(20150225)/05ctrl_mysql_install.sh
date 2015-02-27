#! /bin/bash

ctrl_mysql_install() {

    echo '
    # ------------------------------------------------------------------------------
    ### ctrl_mysql_install!!!
    # ------------------------------------------------------------------------------'
    
    # MySQL
    echo '  1.1 자동설치를 위한 debconf 설정'
    echo "mysql-server-5.5 mysql-server/root_password password $MYSQL_ROOT_PASS" | debconf-set-selections
    echo "mysql-server-5.5 mysql-server/root_password_again password $MYSQL_ROOT_PASS" | debconf-set-selections
    echo "mysql-server-5.5 mysql-server/root_password seen true" | debconf-set-selections
    echo "mysql-server-5.5 mysql-server/root_password_again seen true" | debconf-set-selections
    
    echo '  1.2 mysql-server, python db client 설치'
    apt-get -y install mysql-server python-mysqldb
    
    echo '  1.3 my.cnf 설정(bind-address, max_connections 변경)'
    backup_org ${MY_SQL_CONF}
    
    sed -i "s/^bind\-address.*/bind-address = 0.0.0.0/g" $MY_SQL_CONF
    sed -i "s/^#max_connections.*/max_connections = 512/g" $MY_SQL_CONF
    
    echo '  1.4 ip로 db접속하도록 설정(name resolve 사용안함)'
    echo "[mysqld]
    skip-name-resolve" > /etc/mysql/conf.d/skip-name-resolve.cnf
    
    echo '  1.5 encoding 설정(utf8)'
    echo "[mysqld]
    collation-server = utf8_general_ci
    init-connect='SET NAMES utf8'
    character-set-server = utf8" > /etc/mysql/conf.d/01-utf8.cnf
    
    echo '  1.6 mysql 재시작'
    restart mysql
    
    echo '  1.7 mysql 권한과 접속환경 설정(외부에서도 root로 접속가능하게)'
    mysql -u root -p${MYSQL_ROOT_PASS} -h localhost -e "GRANT ALL ON *.* to root@\"localhost\" IDENTIFIED BY \"${MYSQL_ROOT_PASS}\" WITH GRANT OPTION;"
    mysql -u root -p${MYSQL_ROOT_PASS} -h localhost -e "GRANT ALL ON *.* to root@\"${MYSQL_HOST}\" IDENTIFIED BY \"${MYSQL_ROOT_PASS}\" WITH GRANT OPTION;"
    mysql -u root -p${MYSQL_ROOT_PASS} -h localhost -e "GRANT ALL ON *.* to root@\"%\" IDENTIFIED BY \"${MYSQL_ROOT_PASS}\" WITH GRANT OPTION;"
    mysqladmin -uroot -p${MYSQL_ROOT_PASS} flush-privileges

    echo '>>> check result------------------------------------------------------'
    mysql -u root -p${MYSQL_ROOT_PASS} -h localhost -e "show databases;"    
    echo '#---------------------------------------------------------------------'
}


function ctrl_mysql_uninstall() {

    service mysql stop
    
    apt-get -y remove --purge mysql-server mysql-client mysql-common
    apt-get -y autoremove
    apt-get autoclean

}