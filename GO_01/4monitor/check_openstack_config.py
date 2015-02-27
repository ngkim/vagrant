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

class CloudMonitor():

    def __init__(self):
        
        #
        # 각종 component 프로세스 상태 검사를 위한 component 리스트
        
        #--------------------------------------------------------------------------------
        # 1. nova configuration
        #   nova.conf       nova-compute.conf
        #   api-paste.ini   logging.conf
        #   policy.json     rootwrap.conf
        #--------------------------------------------------------------------------------
        # process                       config file
        #--------------------------------------------------------------------------------
        # /usr/bin/nova-api               /etc/nova/nova.conf
        #                                 /etc/nova/api-paste.ini
        # /usr/bin/nova-cert              /etc/nova/nova.conf
        # /usr/bin/nova-conductor         /etc/nova/nova.conf
        # /usr/bin/nova-consoleauth       /etc/nova/nova.conf
        # /usr/bin/nova-novncproxy        /etc/nova/nova.conf
        # /usr/bin/nova-scheduler         /etc/nova/nova.conf
        # /usr/bin/nova-compute           /etc/nova/nova.conf
        #                                 /etc/nova/nova-compute.conf
        # /usr/bin/nova-novncproxy        /etc/nova/nova.conf
        #--------------------------------------------------------------------------------
        # /usr/sbin/libvirtd -d -l        /etc/libvirt/libvirtd.conf
        
        #--------------------------------------------------------------------------------
        # 2. glance configuration
        #   glance-api.conf        glance-api-paste.ini
        #   glance-registry.conf   glance-registry-paste.ini
        #   policy.json
        #   glance-cache.conf  glance-scrubber.conf
        #--------------------------------------------------------------------------------
        # process                       config file
        #--------------------------------------------------------------------------------
        # /usr/bin/glance-api           /etc/glance/glance-api.conf
        #                               /etc/glance/glance-api-paste.ini
        # /usr/bin/glance-registry      /etc/glance/glance-registry.conf
        #                               /etc/glance/glance-registry-paste.ini
        #--------------------------------------------------------------------------------
        
        #--------------------------------------------------------------------------------
        # 3. cinder configuration
        #   api-paste.ini  cinder.conf  logging.conf  policy.json  rootwrap.conf
        #--------------------------------------------------------------------------------
        # process                       config file
        #--------------------------------------------------------------------------------
        # /usr/bin/cinder-api           /etc/cinder/cinder.conf
        #                               /etc/cinder/api-paste.ini
        # /usr/bin/cinder-scheduler     /etc/cinder/cinder.conf
        # /usr/bin/cinder-volume        /etc/cinder/cinder.conf
        #--------------------------------------------------------------------------------
        
        #--------------------------------------------------------------------------------
        # 4. keystone configuration
        #   keystone.conf  keystone-paste.ini  logging.conf
        #   policy.json    default_catalog.templates
        #--------------------------------------------------------------------------------
        # process                       config file
        #--------------------------------------------------------------------------------
        # /usr/bin/keystone-all         /etc/cinder/keystone.conf
        #                               /etc/cinder/keystone-paste.ini
        #--------------------------------------------------------------------------------
        
        #--------------------------------------------------------------------------------
        # 5. neutron configuration
        #--------------------------------------------------------------------------------
        #   neutron.conf
        #   api-paste.ini
        #   dhcp_agent.ini
        #   l3_agent.ini
        #   metadata_agent.ini
        #   policy.json  rootwrap.conf
        #   /etc/neutron/plugins/ml2/ml2_conf.ini
        #--------------------------------------------------------------------------------
        # process                   config file
        #--------------------------------------------------------------------------------
        # neutron-server
        #                           /etc/neutron/neutron.conf
        #                           /etc/neutron/api-paste.ini
        #                           /etc/neutron/plugins/ml2/ml2_conf.ini
        #                           /etc/default/neutron-server
        # neutron-plugin-openvswitch-agent
        #                           /etc/neutron/neutron.conf
        #                           /etc/neutron/api-paste.ini
        #                           /etc/neutron/plugins/ml2/ml2_conf.ini
        #                           /etc/init/neutron-plugin-openvswitch-agent.conf
        # neutron-dhcp-agent
        #                           /etc/neutron/neutron.conf
        #                           /etc/neutron/api-paste.ini
        #                           /etc/neutron/dhcp_agent.ini
        # neutron-l3-agent
        #                           /etc/neutron/neutron.conf
        #                           /etc/neutron/api-paste.ini
        #                           /etc/neutron/l3_agent.ini
        # neutron-metadata-agent    /etc/neutron/neutron.conf
        #                           /etc/neutron/api-paste.ini
        #                           /etc/neutron/metadata_agent.ini
        ##--------------------------------------------------------------------------------
        
        #--------------------------------------------------------------------------------
        # 6. horizon configuration
        #--------------------------------------------------------------------------------
        #   /etc/apache2/apache2.conf httpd.conf  ports.conf
        #   /etc/openstack-dashboard/local_settings.py 
        #--------------------------------------------------------------------------------
        
        self.allinone_config = collections.OrderedDict()
        
        self.allinone_config['nova']=[
            '/etc/nova/nova.conf',
            '/etc/nova/api-paste.ini',
            '/etc/nova/nova-compute.conf',            
            '/etc/nova/policy.json',
            '/etc/nova/rootwrap.conf',
            '/etc/nova/logging.conf',            
            '/etc/libvirt/libvirtd.conf'
        ]
            
        self.allinone_config['glance']=[
            '/etc/glance/glance-api.conf',        
            '/etc/glance/glance-api-paste.ini',
            '/etc/glance/glance-registry.conf',   
            '/etc/glance/glance-registry-paste.ini',
            '/etc/glance/policy.json',
            '/etc/glance/glance-cache.conf',  
            '/etc/glance/glance-scrubber.conf'                                      
        ]
        
        self.allinone_config['cinder']=[
            '/etc/cinder/api-paste.ini',
            '/etc/cinder/cinder.conf',
            '/etc/cinder/logging.conf',
            '/etc/cinder/policy.json',
            '/etc/cinder/rootwrap.conf'                                      
        ]
        
        self.allinone_config['keystone']=[
            '/etc/keystone/keystone.conf',
            '/etc/keystone/keystone-paste.ini',
            '/etc/keystone/logging.conf',                                      
            '/etc/keystone/policy.json',
            '/etc/keystone/default_catalog.templates'
        ]
        
        self.allinone_config['neutron']=[
            '/etc/neutron/neutron.conf',
            '/etc/neutron/api-paste.ini',
            '/etc/neutron/dhcp_agent.ini',
            '/etc/neutron/l3_agent.ini',
            '/etc/neutron/metadata_agent.ini',
            '/etc/neutron/policy.json',
            '/etc/neutron/rootwrap.conf',
            '/etc/neutron/plugins/ml2/ml2_conf.ini'
        ]       
        
        self.allinone_config['horizon']=[
            '/etc/apache2/apache2.conf',
            '/etc/apache2/httpd.conf',  
            '/etc/apache2/ports.conf',
            '/etc/apache2/conf-available/openstack-dashboard.conf',
            '/etc/openstack-dashboard/local_settings.py' 
        ]                
        
        self.ctrlnnode_config = collections.OrderedDict()        
        self.ctrlnnode_config['nova']=[
            '/etc/nova/nova.conf',
            '/etc/nova/api-paste.ini',                        
            '/etc/nova/policy.json',
            '/etc/nova/rootwrap.conf',
            '/etc/nova/logging.conf',            
            '/etc/libvirt/libvirtd.conf'
        ]
            
        self.ctrlnnode_config['glance']=[
            '/etc/glance/glance-api.conf',        
            '/etc/glance/glance-api-paste.ini',
            '/etc/glance/glance-registry.conf',   
            '/etc/glance/glance-registry-paste.ini',
            '/etc/glance/policy.json',
            '/etc/glance/glance-cache.conf',  
            '/etc/glance/glance-scrubber.conf'                                      
        ]
        
        self.ctrlnnode_config['cinder']=[
            '/etc/cinder/api-paste.ini',
            '/etc/cinder/cinder.conf',
            '/etc/cinder/logging.conf',
            '/etc/cinder/policy.json',
            '/etc/cinder/rootwrap.conf'                                      
        ]
        
        self.ctrlnnode_config['keystone']=[
            '/etc/keystone/keystone.conf',
            '/etc/keystone/keystone-paste.ini',
            '/etc/keystone/logging.conf',                                      
            '/etc/keystone/policy.json',
            '/etc/keystone/default_catalog.templates'
        ]
        
        self.ctrlnnode_config['neutron']=[
            '/etc/neutron/neutron.conf',
            '/etc/neutron/api-paste.ini',
            '/etc/neutron/dhcp_agent.ini',
            '/etc/neutron/l3_agent.ini',
            '/etc/neutron/metadata_agent.ini',
            '/etc/neutron/policy.json',
            '/etc/neutron/rootwrap.conf',
            '/etc/neutron/plugins/ml2/ml2_conf.ini'
        ]       
        
        self.ctrlnnode_config['horizon']=[
            '/etc/apache2/apache2.conf',
            '/etc/apache2/httpd.conf',  
            '/etc/apache2/ports.conf'
            '/etc/apache2/conf-available/openstack-dashboard.conf',
            '/etc/openstack-dashboard/local_settings.py' 
        ]
        
                
        self.dedi_cnode_config = collections.OrderedDict()
        self.dedi_cnode_config['nova']=[
            '/etc/nova/nova.conf',
            '/etc/nova/nova-compute.conf',        
            '/etc/libvirt/libvirtd.conf'
        ]
        
        self.dedi_cnode_config['neutron']=[
            '/etc/neutron/neutron.conf',
            '/etc/neutron/api-paste.ini',
            '/etc/neutron/plugins/ml2/ml2_conf.ini'
        ]
    
                                    
    def check_openstack_config(self, tag, config_dict):
        
        log.info("-"*80)                    
        serv_info = self.rssh.getservinfo(tag)[0]
        log.info("# Host <%s> :: %s check openstack config" % (tag, serv_info))
        log.info("-"*80)        
        
        
        for component, configs in config_dict.iteritems():        
            
            for conf_file in configs:                
                cmd = 'cat %s' % conf_file
                
                log.info("-"*80)
                log.info("# %s" % cmd)                
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
        self.rssh.register('west-cnode02', '211.224.204.157', 22, 'root', 'ohhberry3333' )        
    
        self.rssh.register('east-ctrl',    'controller', 22, 'root', 'ohhberry3333' )
        self.rssh.register('east-cnode01', 'cnode01', 22, 'root', 'ohhberry3333' )
        self.rssh.register('east-cnode02', 'cnode02', 22, 'root', 'ohhberry3333' )
        self.rssh.register('east-cnode03', 'cnode03', 22, 'root', 'ohhberry3333' )
        
        log.info("""
        # ----------------------------------------------------------------------
        # LJG todo: 속도개선을 위해서는 egrep으로 모두 한번에 검색해오고
        #           내부에서 파싱하자
        # ----------------------------------------------------------------------
        """)
        
        while True:      
            try:
                self.check_openstack_config('east-ctrl',    self.ctrlnnode_config)
                self.check_openstack_config('east-cnode01', self.dedi_cnode_config)
                self.check_openstack_config('east-cnode02', self.dedi_cnode_config)
                self.check_openstack_config('east-cnode03', self.dedi_cnode_config)
            except:                            
                log.error(traceback.format_exc())
                
            sys.exit()
             
            random_sec = 3                        
            time.sleep(random_sec)
            
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
