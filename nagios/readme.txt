http://system-monitoring.readthedocs.org/en/latest/nagios.html
http://xmodulo.com/nagios-remote-plugin-executor-nrpe-linux.html

1. install nagios-nrpe-server
apt-get install nagios-nrpe-server 
apt-get install nagios-nrpe-plugin

2. check nrpe-server port: TCP 5666
root@vagrant-ubuntu-trusty-64:/vagrant# netstat -tlpn
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      1214/sshd       
tcp        0      0 0.0.0.0:25              0.0.0.0:*               LISTEN      10082/master    
tcp        0      0 0.0.0.0:5666            0.0.0.0:*               LISTEN      7948/nrpe       
tcp        0      0 0.0.0.0:39144           0.0.0.0:*               LISTEN      599/rpc.statd   
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      568/rpcbind     
tcp6       0      0 :::22                   :::*                    LISTEN      1214/sshd       
tcp6       0      0 :::25                   :::*                    LISTEN      10082/master    
tcp6       0      0 :::36893                :::*                    LISTEN      599/rpc.statd   
tcp6       0      0 :::5666                 :::*                    LISTEN      7948/nrpe       
tcp6       0      0 :::111                  :::*                    LISTEN      568/rpcbind     
tcp6       0      0 :::80                   :::*                    LISTEN      11429/apache2  

3. /etc/nagios/nrpe.cfg 에 상대방 IP 입력

allowed_hosts=127.0.0.1,192.168.10.2

4. nagios-nrpe-server 재시작
service nagios-nrpe-server restart

5. check_nrpe로 연결 체크
/usr/lib/nagios/plugins/check_nrpe -H 192.168.10.2

vim /etc/nagios-plugins/config/check_nrpe.cfg 

6. /etc/nagios3/conf.d/nrpe.cfg

## example 1: check process XYZ ##
define service {
        host_name                       server-1
        service_description             Check Process XYZ
        check_command                   check_nrpe!check_process_XYZ
        check_interval                  1
        use                             generic-service
}

