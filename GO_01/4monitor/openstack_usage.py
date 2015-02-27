#!/usr/bin/env python
# -*- coding: utf-8 -*-
    
# LJG: pexpect에서 "'"처리를 제대로 해주지 못해 복합적인 linux 명령어를 사용하지 못하고 있다.
#  예)  netstat -naop | egrep '(8501|8502|8503|8504|6379)' | grep LISTEN -> 에러발생


import time
import os, sys, traceback
import collections

sys.path.append('/root/openstack/util')

from myDBHelper import *
from myUtil import *
from mySSHHelper import *
from myLogger  import *

log = myLogger(tag='ljg', logdir='./log', loglevel='debug', logConsole=True).get_instance()

    
# 
# if len(sys.argv) > 1:
#     prog    = sys.argv[0]
#     host_name = sys.argv[1]
# 
#     log.debug(prog)
#     log.debug(host_name)
#     
# else:
#     log.debug("""
#         usage:: host_monitor.py host_name
#           ex) host_monitor.py controller
#               host_monitor.py cnode02            
#     """)
#     exit


class CloudMonitor():
    def __init__(self):           
        
        #
        # openstack usage를 점검하기 위한 CLI        
        
        #     nova host-list
        #     nova host-describe devstack
        #    nova list
        #    nova diagnostics myCirrosServer
        #    nova usage-list

        self.usage_cli = collections.OrderedDict()        
        self.usage_cli['nova']=['nova hostlist','nova-manage service list']
        self.usage_cli['neutron']=['neutron net-list']
        self.usage_cli['glance']=['glance image-list']
        self.usage_cli['cinder']=['cinder list']
        self.usage_cli['keystone']=['keystone endpoint-list']        
        
        """
         nova list
         nova list --all-tenants
         nova host-list
         nova host-describe cnode02
         nova host-describe controller
         nova list
         nova list --all-tenants
         nova diagnostics 001_client
         nova diagnostics gmgmt_vm
         nova diagnostics 1adf4fcd-faf2-4167-ae67-c3a9fae295fb
         nova show gmgmt_vm
         nova usage-list
         keystone tenant-list
         keystone user-list
         nova hypervisor-list         
         nova hypervisor-servers controller
         nova hypervisor-servers cnode02
         nova hypervisor-show controller
         nova hypervisor-show cnode02
         nova hypervisor-stats
         
         nova list
         nova interface-list gmgmt_vm
         nova usage-list
         nova usage
         
         neutron ext-list          
         neutron ext-show l3_agent_scheduler
         neutron ext-show provider
         neutron ext-show router
         neutron ext-show agent
         neutron ext-show quotas
         neutron firewall-list
         neutron floatingip-list
         neutron floatingip-show 4e99854e-a046-4ad2-b517-ce4b21dc3c57
         neutron gateway-device-list
         neutron l3-agent-list-hosting-router 
         neutron net-external-list
         neutron net-list
         neutron net-gateway-list
         neutron nec-packet-filter-list
         neutron net-list
         neutron net-list-on-dhcp-agent
         neutron port-list
         neutron port-show jini_guest_port-1
         neutron port-show f0653e4c-677a-455f-beed-eb5fa0f35c10
         neutron queue-list
         neutron quota-list
         neutron quota-show
         neutron router-list
         neutron router-port-list
         neutron router-port-list global_mgmt_router
        """
                    
    def check_allinone_openstack_component(self, tag):
        
        log.info("-"*80)                    
        serv_info = self.rssh.getservinfo(tag)[0]
        log.info("# Host <%s> :: %s component status" % (tag,serv_info))
        log.info("-"*80)
        for key, val in self.allinone_component.iteritems():
            log.info("")
            log.info("# [%s] componet list ::" % (key))
            for component in val:
                cmd = """ps -ef | grep 'python' | grep '%s' | grep -v grep | wc -l """ % (component)                
                cmd = """ps -ef | grep '%s' | grep -v grep | wc -l """ % (component)
                cmd = cmd.replace("'", "\\'").replace('"', '\\"')
                result = self.rssh.doRemoteCommand (tag, cmd)
                log.info("%30s -> %s" % (component, result))
                
        log.info("-"*80)

    def check_dedi_cnode_openstack_component(self, tag):
        
        log.info("-"*80)                    
        serv_info = self.rssh.getservinfo(tag)[0]
        log.info("# Host <%s> :: %s component status" % (tag,serv_info))
        log.info("-"*80)
        for key, val in self.dedi_cnode_component.iteritems():
            log.info("")
            log.info("# [%s] componet list ::" % (key))
            for component in val:
                cmd = """ps -ef | grep 'python' | grep '%s' | grep -v grep | wc -l """ % (component)                
                cmd = """ps -ef | grep '%s' | grep -v grep | wc -l """ % (component)
                cmd = cmd.replace("'", "\\'").replace('"', '\\"')
                result = self.rssh.doRemoteCommand (tag, cmd)
                log.info("%30s -> %s" % (component, result))
                
        log.info("-"*80)
    
    def check_openstack_component_cli_old(self, tag):
        
        log.info("-"*80)                    
        serv_info = self.rssh.getservinfo(tag)[0]
        log.info("# Host <%s> :: %s component cli status" % (tag,serv_info))
        log.info("-"*80)
        
        session = self.rssh.getRemoteShell(tag)
                
        # ssh 세션을 접속했을때 환경변수가 없으므로 CLI 실행을 위한 환경설정
        COMMAND_PROMPT = '[$#] ' 
        session.sendline('export OS_TENANT_NAME=admin')
        session.sendline('export OS_USERNAME=admin')
        session.sendline('export OS_PASSWORD=ohhberry3333')
        session.sendline('export OS_AUTH_URL=http://controller:5000/v2.0/')
        session.sendline('export OS_NO_CACHE=1')
        session.sendline('export OS_VOLUME_API_VERSION=2')               
        
        session.sendline('env | grep OS_')
        session.expect([pexpect.TIMEOUT, pexpect.EOF, COMMAND_PROMPT], timeout=2)
        result = session.before
        log.info("%30s -> \n%s" % ('환경변수 설정내역', result))
        
        session.before = ""
                
        for key, val in self.test_cli.iteritems():
            log.info("")
            log.info("# [%s] componet list ::" % (key))
            for cmd in val:                
                # cli 실행
                cmd = cmd.replace("'", "\\'").replace('"', '\\"')
                session.sendline(cmd)   
                #session.expect([pexpect.TIMEOUT, pexpect.EOF, COMMAND_PROMPT])
                result = session.before                                 
                log.info("%30s -> \n%s" % (cmd, result))
                session.before = ""
        
        session.close() # -> important
                
        log.info("-"*80)
    
    def check_openstack_component_cli(self, tag):
        
        log.info("\n\n\n\n")
        log.info("#"*80)                    
        serv_info = self.rssh.getservinfo(tag)[0]        
        log.info("# Host <%s> :: %s component cli status" % (tag,serv_info))
        log.info("#"*80)        
                
        for key, val in self.test_cli.iteritems():
            log.info("")
            log.info("# [%s] componet list ::" % (key))
            for cmd in val:                
                # cli 실행
                cmd = cmd.replace("'", "\\'").replace('"', '\\"')                
                # ssh 세션을 접속했을때 환경변수가 없으므로 CLI 실행을 위한 환경설정 필요
                env_cmds="export OS_TENANT_NAME=admin;export OS_USERNAME=admin;export OS_PASSWORD=ohhberry3333;export OS_AUTH_URL=http://controller:5000/v2.0/;export OS_NO_CACHE=1;export OS_VOLUME_API_VERSION=2"                
                cli = "%s; %s" % ("source /root/openstack_rc", cmd)
                cli = "%s; %s" % (env_cmds, cmd)
                result = self.rssh.doRemoteCommand (tag, cli)
                log.info("%30s -> \n%s" % (cmd, result))        
                
        log.info("-"*80)

    def check_ovs_cli(self, tag):
        
        log.info("\n\n\n\n")
        log.info("#"*80)                    
        serv_info = self.rssh.getservinfo(tag)[0]        
        log.info("# Host <%s> :: %s openvswitch cli status" % (tag,serv_info))
        log.info("#"*80)        
                
        for key, val in self.test_ovs_cli.iteritems():
            log.info("")
            log.info("# [%s] ovs cmd list ::" % (key))
            for cmd in val:                
                # cli 실행
                cli = cmd.replace("'", "\\'").replace('"', '\\"')                
                result = self.rssh.doRemoteCommand (tag, cli)
                log.info("%30s -> \n%s" % (cli, result))        
                
        log.info("-"*80)

    def check_virsh_cli(self, tag):
        
        log.info("\n\n\n\n")
        log.info("#"*80)                    
        serv_info = self.rssh.getservinfo(tag)[0]        
        log.info("# Host <%s> :: %s openvswitch cli status" % (tag,serv_info))
        log.info("#"*80)        
                
        for key, val in self.test_virsh_cli.iteritems():
            log.info("")
            log.info("# [%s] virsh cmd list ::" % (key))
            for cmd in val:                
                # cli 실행
                cli = cmd.replace("'", "\\'").replace('"', '\\"')                
                result = self.rssh.doRemoteCommand (tag, cli)
                log.info("%30s -> \n%s" % (cli, result))        
                
        log.info("-"*80)
                                    
    def run(self):
        # period 마다 urc에서 사용할 inventory 재 수집
        # self.period = 300 # LJG-LJG
        #rt = RunTimer(300, self.get_agent_status())
        #rt.start()        
    
        self.rssh = myRSSH()
        self.rssh.timeout = 5
        self.rssh.register('west-ctrl',    '211.224.204.156', 22, 'root', 'ohhberry3333' )
        self.rssh.register('west-cnode02', '211.224.204.157', 22, 'root', 'ohhberry3333' )        
    
        self.rssh.register('east-ctrl',    '211.224.204.147', 22, 'root', 'ohhberry3333' )
        self.rssh.register('east-cnode02', '211.224.204.146', 22, 'root', 'ohhberry3333' )
        
        log.info("""
        # -------------------------------------------------------------------------------
        # LJG todo: 속도개선을 위해서는 egrep으로 모두 한번에 검색해오고
        #           내부에서 파싱하자
        # -------------------------------------------------------------------------------
        """)
        
        while True:
                         
            try:
                
                self.check_openstack_component_cli('west-ctrl')                
                self.check_openstack_component_cli('west-cnode02')                
                
                self.check_ovs_cli('west-ctrl')
                self.check_virsh_cli('west-ctrl')
                
            except:
                errmsg = "%s.%s Error:: \n<<%s>>" % (self.module, 'check_neutron', traceback.format_exc())            
                log.error(errmsg)            
            
            sys.exit()
             
            random_sec = 3                        
            time.sleep(random_sec)
                        
    def stop(self):
        self.stopflag.set()
        pass
###############################################################################
       
def main():
    pid   = os.getpid()
    pname = process_name()
            
    cm = CloudMonitor()
    cm.run()        
       
if __name__ == '__main__':   
    
    import sys, os
    
    main()       
    
    
    input('!! Wait & See !!')
    
    """        
    if len(sys.argv) == 1:
        
        pid = os.fork()    
        if pid:
            print("부모프로세스 종료 PID[%s] -> 자식 프로세스[%s]" % (os.getpid(), pid))
            os._exit(0)        
        print("자식프로세스 PID[%s] -> 부모 프로세스[%s]" % (os.getpid(), os.getppid()))
        
        sys.stdout = open("/dev/null", 'w')
        sys.stderr = open("/dev/null", 'w')
            
        main()        
        
    else:
            
        main()        
        input('!! Wait forever for thread/process start !!')
    """
