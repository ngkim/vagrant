#!/usr/bin/python -B
# -*- coding: utf-8 -*-
    
import paramiko

class myParamiko():
    """
        paramiko를 이용한 interactive 원격쉘 실행 프로그램
    """    

    def __init__(self):
        self.debug      = False # remote ssh stdin/out display to console
        self.fdebug     = True  # remote ssh stdin/out display to file
        self.timeout    = 3     # remote ssh command timeout
        
        # ssh를 사용할 채널에 관한 meta 정보
        self.servinfo   = {}
        # ssh 로 연결된 채널 인스턴스 정보
        self.servinst   = {}
    
    def register(self, name, ip, port, id, pw):
        self.servinfo[name] = (ip, port, id, pw)
            
    def serv_keys(self):
        return self.servinfo.keys()
    
    def getservinfo(self, name):
        if self.servinfo.has_key(name):
            return self.servinfo[name]
        else:
            errmsg = "name[%s] does not exist!! register first!!" % (name)
            print errmsg
            raise RuntimeError(errmsg)

    def getserv_ip(self, name):
        (ip, port, id, pw) = self.getservinfo(name)
        return ip

    def getserv_pw(self, name):
        (ip, port, id, pw) = self.getservinfo(name)
        return pw    
        
    def getserv_instance(self, name):
        if self.servinst.has_key(name):
            return self.servinst[name]
        else:
            errmsg = "name[%s] does not connect!! connect first!!" % (name)
            print errmsg
            raise RuntimeError(errmsg)
    # ------------------------------------------------------------------------------
    
    # --------------------------------------------------------------------------
    def connect(self, name):
        """name tag에 해당하는 ssh 서버에 접속"""
        
        if self.servinst.has_key(name):                
            errmsg = "name[%s] is already connected!!" % (name)
            print errmsg
            raise RuntimeError(errmsg)
            
        (ip, port, id, pw) = self.getservinfo(name)
            
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(ip, port=port, username=id, password=pw, timeout=self.timeout )
        
        self.servinst[name] = client

    # --------------------------------------------------------------------------
    def run(self, name, command):
        """
            명령을 실행하고 결과를 포함하는 stdout 채널을 리턴한다.
            기본적으로는 명령의 결과를 리턴하나,
            다양하게 결과를 분석해서 처리해야 하는 경우가 많으므로
            결과가 저장되있는 stdout 채널을 직접 리턴한다. 
        """
        
        conn = self.getserv_instance(name)
        stdin, stdout, stderr = conn.exec_command(command)
        stdin.close()
        
        return stdout
        
        """
        for line in stdout.read().splitlines():
            print 'host: %s: %s' % (name, line)
                
        return stdout.readlines()
        """
        
    def run_with_result(self, name, command):
        
        conn = self.getserv_instance(name)
        stdin, stdout, stderr = conn.exec_command(command)
        stdin.close()
        
        #return stdout.readlines()
        return stdout.read()

    def close(self, name):
        conn = self.getserv_instance(name)
        conn.close()
   
    def close_all(self):
        for name, conn in self.servinst.iteritems():
            print "%-20s close !!" % (name)
            conn.close()

# ------------------------------------------------------------------------------

if __name__ == '__main__':
    
    # main routine
    try:
        rssh = myParamiko()
        rssh.timeout = 10
        rssh.debug = True
        rssh.register('ctrl',    '221.151.188.15', 22, 'root', 'ohhberry3333')
        rssh.register('cnode01', '221.151.188.16', 22, 'root', 'ohhberry3333')
        rssh.register('cnode02', '221.151.188.17', 22, 'root', 'ohhberry3333')
        rssh.register('local', '211.224.204.153', 30022, 'vagrant', 'vagrant')
        rssh.register('local', '211.224.204.153', 30022, 'root', 'tkfkdgo7')
        
        tag = 'local'
        rssh.connect(tag)
        print "-"*80      
        cmd = 'ps -ef | grep python | grep nova-api | grep -v grep'
        #cmd = 'ps -ef'
        env_cmds="export OS_TENANT_NAME=admin;export OS_USERNAME=admin;export OS_PASSWORD=ohhberry3333;export OS_AUTH_URL=http://controller:5000/v2.0/;export OS_NO_CACHE=1;export OS_VOLUME_API_VERSION=2"
        #cmd="nova list"
        cli_cmd = "%s;%s" % (env_cmds, cmd) 
        """
        rch = rssh.run(tag', cmd)        
        for line in rch.read().splitlines():
            print '%s: %s' % ('ctrl', line)
        """   
        
        print rssh.run_with_result(tag, cli_cmd)
        
        cmd_list = ['uptime', 'mpstat', 'df -h', 'iostat']
        for cmd in cmd_list:
            print "-"*80        
            print cmd
            print "-"*80
            result = rssh.run_with_result(tag, cmd)
            print '%s: %s' % (tag, result)
            print "-"*80
            
            
        rssh.close(tag)

    except Exception, e:
        print "@"*80
        print str(e)
        print "@"*80
        import traceback
        traceback.print_exc()
        print "@"*80        
        import os
        os._exit(1)
        

