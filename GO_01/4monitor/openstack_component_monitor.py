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
        # 각종 component 프로세스 상태 검사를 위한 component 리스트
        self.allinone_component = collections.OrderedDict()
        
        self.allinone_component['nova']=['nova-api', 'nova-conductor','nova-scheduler','nova-cert',
                                    'nova-consoleauth','nova-novncproxy',
                                    'nova-compute','nova-api-metadata']
        self.allinone_component['neutron']=['neutron-server',
                                            'neutron-openvswitch-agent',
                                            'neutron-dhcp-agent','neutron-l3-agent',
                                            'neutron-metadata-agent','neutron-ns-metadata-proxy']
        self.allinone_component['cinder']=['cinder-api', 'cinder-scheduler','cinder-volume']
        self.allinone_component['glance']=['glance-api', 'glance-registry']
        self.allinone_component['keystone']=['keystone-all']
        
        self.allinone_component['nova_utils']=['libvirt']
        self.allinone_component['neutron_utils']=['dnsmasq','ovsdb-client','ovsdb-server','ovs-vswitchd']                                                    
        self.allinone_component['cinder_utils']=['iscsid', 'tgtd']
        self.allinone_component['horizon_utils']=['apache2','memcached','django']
        self.allinone_component['message_utils']=['epmd', 'beam.smp']
        self.allinone_component['db_utils']=['mysqld']
        
        
        
        self.ctrlnnode_component = collections.OrderedDict()        
        self.ctrlnnode_component['nova']=['nova-api', 'nova-conductor','nova-scheduler','nova-cert',
                                    'nova-consoleauth','nova-novncproxy']
        self.ctrlnnode_component['neutron']=['neutron-server',
                                            'neutron-openvswitch-agent',
                                            'neutron-dhcp-agent','neutron-l3-agent',
                                            'neutron-metadata-agent','neutron-ns-metadata-proxy']
        self.ctrlnnode_component['cinder']=['cinder-api', 'cinder-scheduler','cinder-volume']
        self.ctrlnnode_component['glance']=['glance-api', 'glance-registry']
        self.ctrlnnode_component['keystone']=['keystone-all']        
        
        self.ctrlnnode_component['neutron_utils']=['dnsmasq','ovsdb-client','ovsdb-server','ovs-vswitchd']                                                    
        self.ctrlnnode_component['cinder_utils']=['iscsid', 'tgtd']
        self.ctrlnnode_component['horizon_utils']=['apache2','memcached','django']
        self.ctrlnnode_component['message_utils']=['epmd', 'beam.smp']
        self.ctrlnnode_component['db_utils']=['mysqld']        
        
        self.dedi_cnode_component={}
        self.dedi_cnode_component = collections.OrderedDict()
        
        self.dedi_cnode_component['nova']=['nova-compute']       
        self.dedi_cnode_component['neutron']=['neutron-openvswitch-agent']
        self.dedi_cnode_component['nova_utils']=['libvirt']
        self.dedi_cnode_component['neutron_utils']=['dnsmasq','ovsdb-client','ovsdb-server','ovs-vswitchd']                                            
        self.dedi_cnode_component['cinder_utils']=['iscsid', 'tgtd']
                    
        
        #
        # 각종 component 의 CLI를 점검하기 위한 명령 리스트        
        
        self.test_cli = collections.OrderedDict()        
        self.test_cli['nova']=['nova list','nova-manage service list']
        self.test_cli['neutron']=['neutron net-list']
        self.test_cli['glance']=['glance image-list']
        self.test_cli['cinder']=['cinder list']
        self.test_cli['keystone']=['keystone endpoint-list']        
        
        #
        # 각종 ovs 점검하기 위한 명령 리스트
        self.test_ovs_cli = collections.OrderedDict()     
        self.test_ovs_cli['ovs']=['ovs-vsctl show','ovsdb-client dump','ovs-dpctl show']
        
        self.test_virsh_cli = collections.OrderedDict()        
        self.test_virsh_cli['virsh']=['virsh list']
                
        OVS_Aliases = """
        alias novh='nova hypervisor-list'
        alias novm='nova-manage service list' 
        alias ovstart='/usr/share/openvswitch/scripts/ovs-ctl start' 
        alias ovs='ovs-vsctl show'
        alias ovsd='ovsdb-client dump'
        alias ovsp='ovs-dpctl show'
        alias ovsf='ovs-ofctl '
        alias ologs="tail -n 300 /var/log/openvswitch/ovs-vswitchd.log"
        alias vsh="virsh list"
        alias ovap="ovs-appctl fdb/show "
        alias ovapd="ovs-appctl bridge/dump-flows "
        alias dpfl="ovs-dpctl dump-flows "
        alias ovtun="ovs-ofctl dump-flows br-tun"
        alias ovint="ovs-ofctl dump-flows br-int"
        alias ovap="ovs-appctl fdb/show "
        alias ovapd="ovs-appctl bridge/dump-flows "
        alias dfl="ovs-ofctl -O OpenFlow13 del-flows "
        alias ovls="ovs-ofctl -O OpenFlow13  dump-flows br-int"
        alias dpfl="ovs-dpctl dump-flows "
        alias ofport=" ovs-ofctl -O OpenFlow13 dump-ports br-int"
        alias del=" ovs-ofctl -O OpenFlow13 del-flows "
        alias delman=" ovs-vsctl del-manager"
        # Replace the IP with the ODL controller or OVSDB manager address
        alias addman=" ovs-vsctl set-manager tcp:10.0.2.15:6640"
        alias ns="ip netns exec "
        """
        
        self.host_name    = ProcessInfo.getHostName()
        self.host_ip      = ProcessInfo.getHostIp()        
        self.process_name = ProcessInfo.getProcessName()
        self.process_id   = ProcessInfo.getPID()        
        self.thread_name  = ThreadInfo.getThreadName()          
        self.module       = 'CloudMonitor' 
        
        log.info("##############################################")
        log.info( "module_name:: [%s] INIT" % self.module)
        log.info("----------------------------------------------")
        log.info( "    host_name::    [%s]" % self.host_name)
        log.info( "    host_ip::      [%s]" % self.host_ip)        
        log.info( "    process_name:: [%s]" % self.process_name)
        log.info( "    process_id::   [%s]" % self.process_id)        
        log.info( "    thread_name::  [%s]" % self.thread_name)
        log.info("##############################################")

    # NGKIM: filename for ps list
    def get_pslist_file_name(self, tag):
        return "/tmp/processes.%s.log" % tag
    
    # NGKIM: store ps list into a file
    def save_pslist(self, tag):        
        filename=self.get_pslist_file_name(tag)
        
        cmd = "ps -ef | grep -v grep "
         
        data = self.rssh.doRemoteCommand (tag, cmd)        
                
        fo = open(filename, "w")
        fo.write(data)
        fo.close()
        
    # NGKIM: get process count from ps list file
    def get_ps_count(self, tag, component):
        
        cmd = """cat %s | grep '%s' | wc -l """ % (self.get_pslist_file_name(tag), component)
               
        import subprocess
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
        (output, err) = p.communicate()
        
        return output.strip()
                                    
    def check_allinone_openstack_component(self, tag):
        
        log.info("-"*80)                    
        serv_info = self.rssh.getservinfo(tag)[0]
        log.info("# Host <%s> :: %s component status" % (tag,serv_info))
        log.info("-"*80)
        
        # NGKIM
        self.save_pslist(tag)
        
        for key, val in self.allinone_component.iteritems():
            log.info("")
            log.info("# [%s] allinone component list ::" % (key))
            for component in val:
                cmd = """ps -ef | grep 'python' | grep '%s' | grep -v grep | wc -l """ % (component)                
                cmd = """ps -ef | grep '%s' | grep -v grep | wc -l """ % (component)
                cmd = cmd.replace("'", "\\'").replace('"', '\\"')
                
                #result = self.rssh.doRemoteCommand (tag, cmd)
                #log.info("%30s -> %s" % (component, result))
                
                # NGKIM - use stored process list file
                result = self.get_ps_count(tag, component)  # NGKIM
                log.info("%30s -> %s" % (component, result))
                
        log.info("-"*80)

    def check_ctrlnnode_openstack_component(self, tag):
        
        log.info("-"*80)                    
        serv_info = self.rssh.getservinfo(tag)[0]
        log.info("# Host <%s> :: %s ctrl-nnode component status" % (tag,serv_info))
        log.info("-"*80)
        
        # NGKIM
        self.save_pslist(tag)
        
        for key, val in self.ctrlnnode_component.iteritems():
            log.info("")
            log.info("# [%s] component list ::" % (key))
            for component in val:
                cmd = """ps -ef | grep 'python' | grep '%s' | grep -v grep | wc -l """ % (component)                
                cmd = """ps -ef | grep '%s' | grep -v grep | wc -l """ % (component)
                cmd = cmd.replace("'", "\\'").replace('"', '\\"')
                
                #result = self.rssh.doRemoteCommand (tag, cmd)
                #log.info("%30s -> %s" % (component, result))
                
                # NGKIM - use stored process list file
                result = self.get_ps_count(tag, component)  # NGKIM
                log.info("%30s -> %s" % (component, result))
                
        log.info("-"*80)
        
    def check_dedi_cnode_openstack_component(self, tag):
        
        log.info("-"*80)                    
        serv_info = self.rssh.getservinfo(tag)[0]
        log.info("# Host <%s> :: %s dedi-cnode component status" % (tag,serv_info))
        log.info("-"*80)
        
        # NGKIM
        self.save_pslist(tag)
        
        for key, val in self.dedi_cnode_component.iteritems():
            log.info("")
            log.info("# [%s] component list ::" % (key))
            for component in val:
                cmd = """ps -ef | grep 'python' | grep '%s' | grep -v grep | wc -l """ % (component)                
                cmd = """ps -ef | grep '%s' | grep -v grep | wc -l """ % (component)
                cmd = cmd.replace("'", "\\'").replace('"', '\\"')
                
                #result = self.rssh.doRemoteCommand (tag, cmd)
                #log.info("%30s -> %s" % (component, result))
                
                # NGKIM - use stored process list file
                result = self.get_ps_count(tag, component)
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
    
        self.rssh.register('east-ctrl',    'controller', 22, 'root', 'ohhberry3333' )
        self.rssh.register('east-cnode01', 'cnode01', 22, 'root', 'ohhberry3333' )
        self.rssh.register('east-cnode02', 'cnode02', 22, 'root', 'ohhberry3333' )
        self.rssh.register('east-cnode03', 'cnode03', 22, 'root', 'ohhberry3333' )
        
        log.info("""
        # -------------------------------------------------------------------------------
        # LJG todo: 속도개선을 위해서는 egrep으로 모두 한번에 검색해오고
        #           내부에서 파싱하자
        # -------------------------------------------------------------------------------
        """)
        
        while True:
                         
            try:
                
                #self.check_allinone_openstack_component('west-ctrl')
                #self.check_dedi_cnode_openstack_component('west-cnode02')                
                
                self.check_ctrlnnode_openstack_component('east-ctrl')
                self.check_dedi_cnode_openstack_component('east-cnode01')
                self.check_dedi_cnode_openstack_component('east-cnode02')
                self.check_dedi_cnode_openstack_component('east-cnode03')
                
            except:
                errmsg = "%s.%s Error:: \n<<%s>>" % (self.module, 'openstack_monitor', traceback.format_exc())            
                log.error(errmsg)            
            
            sys.exit()
             
            random_sec = 3                        
            time.sleep(random_sec)        
            
    def pexpect_test(self):
        
        self.rssh = myRSSH()
        self.rssh.timeout = 5
        self.rssh.register('cluster_1', '10.2.8.191', 22, 'root','manager' )
        
        # netstat -naop | egrep '(8511)'|grep LISTEN|grep -v grep| sort | awk '{print $7}' | cut -d / -f 1 | xargs kill -9
        # cmd = "netstat -naop | egrep '(%s)'|grep LISTEN|grep -v grep| sort | awk '{print $7}' | cut -d / -f 1 | xargs kill -9" % port
        # cmd = "netstat -naop | egrep '(%s)'|grep LISTEN|grep -v grep| sort | awk '{print $7}' | cut -d / -f 1" % port
        # params_map['command'] = """ps -ef -L | grep python; netstat -naop | egrep '(%s)'""" % ('8511|8512')
        # alias cmport = 'netstat -naop | egrep '\''(8501|8502|8503|8504|8510|8511|8512)'\''|grep LISTEN|sort'
        # ps -ef | egrep '(haproxy|redis)' | grep -v egrep | wc -l
        # netstat -naop | egrep '(8501|8502|8503|8504|6379)' | grep LISTEN|sort | awk '{if ($4 && $7) print $4"-"$7}'
         
        log.debug( "#"*80 )
        
        # LJG: egrep 구문(')이 pexpect에서 정상동작하지 않아서 편법으로 다중명령어와 파이썬 명령 활용
        #     원래의도: netstat -naop | egrep '(8501|8502|8503|8504|6379)' | grep LISTEN | sort | awk \\'\\{if ($4 && $7) print $4"-"$7}'
        _cmd = """netstat -naop | grep 6379 | grep LISTEN | grep redis | grep -v grep;
                 netstat -naop | grep 8501 | grep LISTEN | grep haproxy | grep -v grep"""            
        cmd = """netstat -naop | egrep \\'(8501|8502|8503|8504|6379)\\' | grep LISTEN |sort | awk \\'{if ($4 && $7) print $4\\"-\\"$7}\\' """
        
        # LJG: pexpect에서 명령어 실행을 성공하려면 ',"와 같은 escape문자에 대한 적절한 처리가 필요하다.
        # 이를 위해서는 아래와 같이 '\\'문자를 escape문자앞에 2번 넣어주어야 한다.
        #    ' -> \\'
        #    " -> \\"
        # 이를 위해 다음과 같은 전처리가 필요 :
        #    cmd = cmd.replace("'", "\\'").replace('"', '\\"')
        # ex)
        #     before: netstat -naop | egrep '(8501|8502|8503|8504|6379)' | grep LISTEN |sort 
        #     after : netstat -naop | egrep \'(8501|8502|8503|8504|6379)\' | grep LISTEN |sort
        
        cmd = """netstat -naop | egrep '(8501|8502|8503|8504|6379)' | grep LISTEN |sort | awk '{if ($4 && $7) print $4" "$7}' """
        log.debug( "before: <%s>" % cmd )
        cmd = cmd.replace("'", "\\'").replace('"', '\\"')   
        log.debug( "CMD: <%s>" % cmd )
        result = self.rssh.doRemoteCommand ('cluster_1', cmd)
         
        """
        raw format::
        tcp        0      0 0.0.0.0:6379                0.0.0.0:*                   LISTEN      11537/redis-server  off (0.00/0/0)
        tcp        0      0 0.0.0.0:8501                0.0.0.0:*                   LISTEN      32740/haproxy       off (0.00/0/0)
         
        split result::
        ['tcp', '0', '0', '0.0.0.0:6379', '0.0.0.0:*', 'LISTEN', '11537/redis-server', 'off', '(0.00/0/0)']
        ['tcp', '0', '0', '0.0.0.0:8501', '0.0.0.0:*', 'LISTEN', '32740/haproxy', 'off', '(0.00/0/0)']
        """
         
        log.debug( "-"*80 )
        log.debug( "raw format::\n" )
        log.debug( result )
        log.debug( "-"*80 )
    
        log.debug( "split format::\n")
        for line in result.split('\n'):                
            (protocol, recv_queue, send_queue, local_addr, remote_addr, state, pid_program, timer, etc) = line.split()
            listen_ip, listen_port = local_addr.split(':')
            pid, program           = pid_program.split('/')
            print "program[%20s] pid[%s] :: listen_port[%s]" % (program, pid, listen_port)
             
        log.debug( "-"*80 )        
        log.debug( "#"*80 )           
       
                        
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
