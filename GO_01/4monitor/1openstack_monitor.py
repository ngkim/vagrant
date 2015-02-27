#!/usr/bin/python
# -*- coding: utf-8 -*-

import os, traceback, time

import config.monitor_config  # config 정보파일을 import
import sql.sql_collection   # sql 패키지 로딩
import collections, json

from helper.paramikoHelper  import myParamiko
from helper.dbHelper        import myRSQL
from helper.logHelper       import myLogger
from compiler.ast import Node

log = myLogger(tag='openstack_monitor', logdir='./log', loglevel='debug', logConsole=True).get_instance()

class OpenStackMonitor(object):
    """
    클라우드를 구성하는 개별 노드정보와 노드의 
    감시대상 콤포넌트를 구성파일에 읽어와서
    그와 관련된 정보를 수집한다.
    """
    
    def __init__(self):
        self.org_dir= os.getcwd()
        self.init_config_from_dict_config_file()
        
        self.database_connect()
        self.remote_shell_connect()
        
    def __del__(self):
        
        #  데이터베이스를 정리한다.
        if hasattr(self, 'db'):            
            self.db.finish(self.db_tag)    
        
    def init_config_from_dict_config_file(self):
        
        #
        # 모니터링 대상 사이트의 구성정보 로딩
        
        target_site  = config.monitor_config.target_site
        self.conf = getattr(config.monitor_config, target_site)
        
        #
        # 데이터베이스 관련 정보
                
        db_conf      = self.conf['db_info']
        self.db_host = db_conf['db_host']
        self.db_id   = db_conf['id']
        self.db_pw   = db_conf['pw']
        self.db_name = db_conf['db']
        self.db_port = db_conf['port']
        self.db_tag  = db_conf['tag']
        
        log.debug("#"*80)
        log.debug("# db_host    : %s" % self.db_host)
        log.debug("# db_id      : %s" % self.db_id)
        log.debug("# db_pw      : %s" % self.db_pw)
        log.debug("# db_name    : %s" % self.db_name)
        log.debug("# db_port    : %s" % self.db_port)        
                
        #
        # 감시대상 호스트와 호스트 내부의 콤포넌트 정보
        
        # 감시대상 호스트 리스트
        self.host_list = self.conf['host_list']
        
        log.debug("#"*80)
        log.debug("# host_list    : %s" % self.host_list)
        
        # 감시대상 호스트 정보 dictionary
        # prefix: m: management, n: network, c: compute, s: storage
        #         mn: mgmt & network -> controller와 network 기능을 하나의 서버에 설치(비용이슈)
        
        
        log.debug("#"*80)
            
        if 'anode' in self.conf:        
            self.anode   = self.conf['anode']      # allinone node
            
            log.debug("# anode : %s" % self.anode)
            log.debug("#     anode.ip  : %s" % self.anode['ip'])
            log.debug("#     anode.port: %s" % self.anode['port'])
            log.debug("#     anode.id  : %s" % self.anode['id'])
            log.debug("#     anode.pw  : %s" % self.anode['pw'])
            
            # all_in_node 노드 감시대상 콤포넌트
            self.anode_components = self.conf['anode_components']            
            
            log.debug("#"*80)
            log.debug("# anode_components: %s" % self.anode_components)
            
             
        if 'mnnode' in self.conf:
            self.mnnode  = self.conf['mnnode']     # mgmt & network node
            
            log.debug("# mnnode : %s" % self.mnnode)
            log.debug("#     mnnode.ip  : %s" % self.mnnode['ip'])
            log.debug("#     mnnode.port: %s" % self.mnnode['port'])
            log.debug("#     mnnode.id  : %s" % self.mnnode['id'])
            log.debug("#     mnnode.pw  : %s" % self.mnnode['pw'])            
            
            # management & network 노드 감시대상 콤포넌트
            self.mnnode_components = self.conf['mnnode_components']
            log.debug("#"*80)
            log.debug("# mnnode_components: %s" % self.mnnode_components)
            
        if 'mnode' in self.conf:
            self.mnode   = self.conf['mnode']      # dedi mgmt node
            
            log.debug("# mnode: %s" % self.mnode)
            log.debug("#     mnode.ip  : %s" % self.mnode['ip'])
            log.debug("#     mnode.port: %s" % self.mnode['port'])
            log.debug("#     mnode.id  : %s" % self.mnode['id'])
            log.debug("#     mnode.pw  : %s" % self.mnode['pw'])
            
            # management 노드 감시대상 콤포넌트
            self.mnode_components = self.conf['mnode_components']
            log.debug("#"*80)
            log.debug("# mnode_components: %s" % self.mnode_components)
            
        if 'nnode' in self.conf:
            self.nnode   = self.conf['nnode']      # dedi network node
            
            log.debug("# nnode: %s" % self.nnode)
            log.debug("#     nnode.ip  : %s" % self.nnode['ip'])
            log.debug("#     nnode.port: %s" % self.nnode['port'])
            log.debug("#     nnode.id  : %s" % self.nnode['id'])
            log.debug("#     nnode.pw  : %s" % self.nnode['pw'])
            
            # network 노드 감시대상 콤포넌트
            self.nnode_components = self.conf['nnode_components']
            log.debug("#"*80)
            log.debug("# nnode_components: %s" % self.nnode_components)            
            
        if 'cnode01' in self.conf:
            self.cnode01 = self.conf['cnode01']    # dedi cnode01
        
            log.debug("# cnode01: %s" % self.cnode01)
            log.debug("#     cnode01.ip  : %s" % self.cnode01['ip'])
            log.debug("#     cnode01.port: %s" % self.cnode01['port'])
            log.debug("#     cnode01.id  : %s" % self.cnode01['id'])
            log.debug("#     cnode01.pw  : %s" % self.cnode01['pw'])            
        
            # cnode01 노드 감시대상 콤포넌트
            self.cnode01_components = self.conf['cnode_components']
            log.debug("#"*80)
            log.debug("# cnode_components: %s" % self.cnode01_components)
            
        if 'cnode02' in self.conf:
            self.cnode02 = self.conf['cnode02']    # dedi cnode01
        
            log.debug("# cnode02: %s" % self.cnode02)
            log.debug("#     cnode02.ip  : %s" % self.cnode02['ip'])
            log.debug("#     cnode02.port: %s" % self.cnode02['port'])
            log.debug("#     cnode02.id  : %s" % self.cnode02['id'])
            log.debug("#     cnode02.pw  : %s" % self.cnode02['pw'])
            
            # cnode02 노드 감시대상 콤포넌트
            self.cnode02_components = self.conf['cnode_components']
            log.debug("#"*80)
            log.debug("# cnode_components: %s" % self.cnode02_components)
                    
        
    def remote_shell_connect(self):
        
        self.rssh = myParamiko()
        self.rssh.timeout = 3
        self.rssh.debug   = True
        
        for host in self.host_list:
            # 문자열로 된 속성이름을 참조하기 위해 getattr 사용 
            node = getattr(self, host)
            log.debug("%-8s [%s] node <<%s %s %s>> connect" % (host, node['ip'], node['port'], node['id'], node['pw']))
            self.rssh.register( host, node['ip'], node['port'], node['id'], node['pw'] )
            self.rssh.connect(host)
            log.debug("%-8s [%s] node connect done !!!!" % (host, node['ip']))

    def database_connect(self):
        
        self.db     = myRSQL()
        self.db.timeout = 3
        log.debug("%-8s [%s] node <<%s %s %s %s>> connect" % (self.db_tag,
                                              self.db_host, self.db_id, self.db_pw, self.db_name, int(self.db_port)))
        self.db.connect(self.db_tag, \
                        self.db_host, self.db_id, self.db_pw, self.db_name, int(self.db_port) )
    
    # NGKIM: store ps list into a file
    def save_pslist(self, tag):        
        filename=self.get_pslist_file_name(tag)
        
        cmd = "ps -ef | grep -v grep "
         
        ch = self.rssh.run(tag, cmd)
        fo = open(filename, "w")
        for line in ch.read().splitlines():
            # print 'host: %s: %s' % (tag, line)
            fo.write(line+'\n')        
        fo.close()
        
    # NGKIM: get process count from ps list file
    def get_ps_count(self, tag, component):
        
        cmd = """cat %s | grep '%s' | wc -l """ % (self.get_pslist_file_name(tag), component)
               
        import subprocess
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
        (output, err) = p.communicate()
        
        return output.strip()

    # NGKIM: filename for ps list
    def get_pslist_file_name(self, tag):
        return "/tmp/processes.%s.log" % tag
                
        
    def check_openstack_component(self, tag, mon_components, recs_ref):
        
        log.info("-"*80)                    
        serv_info = self.rssh.getservinfo(tag)[0]
        log.info("# Host <%s> :: %s component status" % (tag, serv_info))
        log.info("-"*80)
        
        # NGKIM
        self.save_pslist(tag)
        
        for key, val in mon_components.iteritems():
            log.info("")
            log.info("# [%s] list ::" % (key))
            for component in val:
                cmd = """ps -ef | grep 'python' | grep '%s' | grep -v grep | wc -l """ % (component)                
                cmd = """ps -ef | grep '%s' | grep -v grep | wc -l """ % (component)
                cmd = cmd.replace("'", "\\'").replace('"', '\\"')
                
                # NGKIM - use stored process list file
                running_num = self.get_ps_count(tag, component)
                log.info("%30s -> %s" % (component, running_num))
                
                d = collections.OrderedDict()
                #d['zone']       = zone
                d['host']       = tag
                d['service']    = key
                d['component']  = component
                d['num']        = running_num
            
                recs_ref.append(d)
                
        log.info("-"*80)
        
    def run(self):
        
        recs_ref = []
        
        for host in self.host_list:  
            print host                           
            try:                 
                node = getattr(self, host)
                log.debug("%-8s [%s] node connect" % (host, node['ip']) )
            
                if host == "mnnode":
                    print "mnnode check %s" % host
                    monitor_components = self.mnnode_components
                    self.check_openstack_component(host, monitor_components, recs_ref)                    
                elif "anode" in host:
                    print "anode check %s" % host
                    monitor_components = self.anode_components
                    self.check_openstack_component(host, monitor_components, recs_ref)
                
                elif "cnode01" in host:
                    print "cnode01 check %s" % host
                    monitor_components = self.cnode01_components
                    self.check_openstack_component(host, monitor_components, recs_ref)
                elif "cnode02" in host:
                    print "cnode02 check %s" % host
                    monitor_components = self.cnode02_components
                    self.check_openstack_component(host, monitor_components, recs_ref)
                         
                """
                self.check_ctrlnnode_openstack_component(self.ctrl_tag, recs_ref)            
                recs_json = json.dumps(recs_ref)        
                print recs_json
                """
            
            except:                
                errmsg = "%s Error:: \n<<%s>>" % ('openstack_monitor', traceback.format_exc())            
                print(errmsg)       
                raise RuntimeError(errmsg)                            
            finally:
                self.rssh.close(host)    
        
        
        #recs_json = json.dumps(recs_ref, indent=4, sort_keys=True)
        #log.debug(recs_json)
           
            
if __name__ == "__main__":
    
    OpenStackMonitor().run()
    
