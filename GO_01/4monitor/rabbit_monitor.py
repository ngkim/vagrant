#!/usr/bin/env python
# -*- coding: utf-8 -*-
    
# LJG: pexpect에서 "'"처리를 제대로 해주지 못해 복합적인 linux 명령어를 사용하지 못하고 있다.
#  예)  netstat -naop | egrep '(8501|8502|8503|8504|6379)' | grep LISTEN -> 에러발생


import time
import os, sys, traceback
import collections
from eventlet.processes import Process
from eventlet.wsgi import Server

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
        
        """
        commands examples
        
            rabbitmqctl list_exchanges
            rabbitmqctl list_exchanges | grep topic
            rabbitmqctl cluster_status
            rabbitmqctl list_users
            rabbitmqctl list_vhosts
            rabbitmqctl list_permissions            
            rabbitmqctl list_user_permissions guest
            rabbitmqctl list_parameters
            rabbitmqctl list_queues
            rabbitmqctl list_exchanges
            rabbitmqctl list_bindings
            rabbitmqctl list_connections
            rabbitmqctl list_channels
            rabbitmqctl list_consumers
            rabbitmqctl environment
            rabbitmqctl report
        """ 
        
        self.rabbitmq_commands = collections.OrderedDict()        
        self.rabbitmq_commands['list']=[
            'rabbitmqctl list_exchanges',
            'rabbitmqctl list_exchanges | grep topic',
            'rabbitmqctl cluster_status',
            'rabbitmqctl list_users',
            'rabbitmqctl list_vhosts',
            'rabbitmqctl list_permissions',            
            'rabbitmqctl list_user_permissions guest',
            'rabbitmqctl list_parameters',
            'rabbitmqctl list_queues',
            'rabbitmqctl list_exchanges',
            'rabbitmqctl list_bindings',
            'rabbitmqctl list_connections',
            'rabbitmqctl list_channels',
            'rabbitmqctl list_consumers',
            'rabbitmqctl environment',
            'rabbitmqctl report'
        ]
        
        self.rabbitmq_apis = collections.OrderedDict()        
        self.rabbitmq_apis['node_liveness']="""curl -s http://guest:guest@controller:15672/api/aliveness-test"""
        
        """
        ./rabbitmqadmin -V "/" list exchanges
        
        
        curl -i -u guest:guest http://localhost:15672/api/vhosts
        curl -i -u guest:guest http://localhost:15672/api/overview
        curl -i -u guest:guest http://localhost:15672/api/nodes
        curl -i -u guest:guest http://localhost:15672/api/extensions
        curl -i -u guest:guest http://localhost:15672/api/connections
        curl -i -u guest:guest http://localhost:15672/api/connections/10.0.0.101:57026 -> 10.0.0.101:5672
        curl -i -u guest:guest http://localhost:15672/api/channels
        curl -i -u guest:guest http://localhost:15672/api/exchanges
         
        node_liveness
        curl -s http://guest:guest@localhost:15672/api/aliveness-test/ccm-prod-vhost | grep -c "ok"
        
        
        cluster_size
        curl -s http://guest:guest@localhost:15672/api/nodes | grep -o "contexts" | wc -l
        
        federation_status
        curl -s http://guest:guest@localhost:15672/api/federation-links/ccm-prod-vhost | grep -o "running" | wc -l
        
        queues_high_watermarks
        curl -s -f http://guest:guest@localhost:15672/api/queues/ccm-dev-vhost/user-dlq | jq '.messages_ready'
        curl -s -f http://guest:guest@localhost:15672/api/queues/ccm-dev-vhost/authentication-service | jq '.messages_ready'                        
        
        overall_message_throughput
        curl -s http://guest:guest@localhost:15672/api/vhosts/ccm-prod-vhost | jq '.messages_details.rate'
        curl -s guest:guest http://localhost:15672/api/vhosts/ccm-prod-vhost | jq '.messages_details.rate'
        
        file_descriptors
        curl -s http://guest:guest@localhost:15672/api/nodes/rabbit@${host} | jq '.fd_used<.fd_total*.8'
        
        socket_desriptors
        curl -s http://guest:guest@localhost:15672/api/nodes/rabbit@${host} | jq '.sockets_used<.sockets_total*.8'
        
        erlang_processes
        curl -s http://guest:guest@localhost:15672/api/nodes/rabbit@${host} | jq '.proc_used<.proc_total*.8'
        
        memory_and_diskspace
        curl -s http://guest:guest@localhost:15672/api/nodes/rabbit@${host} | jq '.mem_used<.mem_limit*.8'
        curl -s http://guest:guest@localhost:15672/api/nodes/rabbit@${host} | jq '.disk_free_limit<.disk_free*.8'
        
        process
        rabbitmq-Server
        epmd
        
        /var/log/rabbitmq/rabbit@controller.log
        /var/log/rabbitmq/rabbit@controller-sasl.log
        
        """
        
        
                                    
    def rabbit_status(self, tag):
        
        log.info("-"*80)                    
        serv_info = self.rssh.getservinfo(tag)[0]
        log.info("# Host <%s> :: %s rabbitmq-server status" % (tag,serv_info))
        log.info("-"*80)
        
        cmd = "rabbitmqctl status "
        cmd = cmd.replace("'", "\\'").replace('"', '\\"')
                
        result = self.rssh.doRemoteCommand (tag, cmd)
        
        log.info(result)                
        log.info("-"*80)
    
    def check_rabbitmq_list_commands(self, tag):
        
        log.info("-"*80)                    
        serv_info = self.rssh.getservinfo(tag)[0]
        log.info("# Host <%s> :: %s check rabbitmq status by list commands" % (tag,serv_info))
        log.info("-"*80)        
        
        for command in self.rabbitmq_commands['list']:
            
            cmd = command.replace("'", "\\'").replace('"', '\\"')
            
            log.info("-"*80)
            log.info("# %s" % cmd)
            log.info("-"*80)
            result = self.rssh.doRemoteCommand (tag, cmd)
            log.info(result)            
                
        log.info("-"*80)        
                                    
    def run(self):
        # period 마다 urc에서 사용할 inventory 재 수집
        # self.period = 300 # LJG-LJG
        #rt = RunTimer(300, self.get_agent_status())
        #rt.start()        
    
        self.rssh = myRSSH()
        self.rssh.timeout = 5
        self.rssh.register('west-ctrl',    '211.224.204.156', 22, 'root', 'ohhberry3333' )
        self.rssh.register('east-ctrl',    'controller', 22, 'root', 'ohhberry3333' )
        
        while True:
                         
            try: 
                
                self.check_rabbitmq_list_commands('west-ctrl')
                                                
            except:                            
                log.error(traceback.format_exc())            
            
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
    
    # input('!! Wait & See !!')
    
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

