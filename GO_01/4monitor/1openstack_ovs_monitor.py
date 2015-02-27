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

log = myLogger(tag='ovs_monitor', logdir='./log', loglevel='debug', logConsole=True).get_instance()

class OvsMonitor(object):
    """
    클라우드에 사용하는 OVS 스위치 상태를 수집한다.
    """
    
    def __init__(self):
        self.org_dir= os.getcwd()
        self.init_config_from_dict_config_file()
        
        self.database_connect()
        self.remote_shell_connect()
        
    def __del__(self):
        
        #  데이터베이스를 정리한다.
        if self.db :            
            self.db.finish(self.db_tag)    
        
    def init_config_from_dict_config_file(self):                       
        
        #
        # 데이터베이스 관련 정보
        
        self.db_host = config.monitor_config.seocho_db_info['db_host']
        self.db_id   = config.monitor_config.seocho_db_info['id']
        self.db_pw   = config.monitor_config.seocho_db_info['pw']
        self.db_name = config.monitor_config.seocho_db_info['db']
        self.db_port = config.monitor_config.seocho_db_info['port']
        self.db_tag  = config.monitor_config.seocho_db_info['tag']
        
        log.debug("#"*80)
        log.debug("# db_host    : %s" % self.db_host)
        log.debug("# db_id      : %s" % self.db_id)
        log.debug("# db_pw      : %s" % self.db_pw)
        log.debug("# db_name    : %s" % self.db_name)
        log.debug("# db_port    : %s" % self.db_port)       
        
                
        #
        # 감시대상 호스트와 호스트 내부의 콤포넌트 정보
        
        # 감시대상 호스트 리스트
        self.host_list = config.monitor_config.seocho_monitor['host_list']
        
        log.debug("#"*80)
        log.debug("# host_list    : %s" % self.host_list)
        
        # 감시대상 호스트 정보 dictionary
        # prefix: m: management, n: network, c: compute, s: storage
        #         mn: mgmt & network -> controller와 network 기능을 하나의 서버에 설치(비용이슈)
        self.mnnode    = config.monitor_config.seocho_monitor['mnnode']
        self.cnode01   = config.monitor_config.seocho_monitor['cnode01']
        self.cnode02   = config.monitor_config.seocho_monitor['cnode02']
        
        log.debug("#"*80)
        log.debug("# mnnode : %s" % self.mnnode)
        log.debug("#     mnnode.ip  : %s" % self.mnnode['ip'])
        log.debug("#     mnnode.port: %s" % self.mnnode['port'])
        log.debug("#     mnnode.id  : %s" % self.mnnode['id'])
        log.debug("#     mnnode.pw  : %s" % self.mnnode['pw'])
        
        log.debug("# cnode01: %s" % self.cnode01)
        log.debug("#     cnode01.ip  : %s" % self.cnode01['ip'])
        log.debug("#     cnode01.port: %s" % self.cnode01['port'])
        log.debug("#     cnode01.id  : %s" % self.cnode01['id'])
        log.debug("#     cnode01.pw  : %s" % self.cnode01['pw'])
        
        log.debug("# cnode02: %s" % self.cnode02)
        log.debug("#     cnode02.ip  : %s" % self.cnode02['ip'])
        log.debug("#     cnode02.port: %s" % self.cnode02['port'])
        log.debug("#     cnode02.id  : %s" % self.cnode02['id'])
        log.debug("#     cnode02.pw  : %s" % self.cnode02['pw'])
                
        # management(controller) 노드 감시대상 콤포넌트
        self.mnode_components = config.monitor_config.seocho_monitor['mnode_components']
        # network 노드 감시대상 콤포넌트
        self.nnode_components = config.monitor_config.seocho_monitor['nnode_components']        
        # cnode 노드 감시대상 콤포넌트
        self.cnode_components = config.monitor_config.seocho_monitor['cnode_components']
        # mgmt 와 network 모듈이 함께 설치된 노드의 감시대상 콤포넌트
        self.mnnode_components = config.monitor_config.seocho_monitor['mnnode_components']
        
        
        log.debug("#"*80)
        log.debug("# mnode_components: %s" % self.mnode_components)
        log.debug("#     mnnode_comp.nova         : %s" % self.mnode_components['nova'])
        log.debug("#     mnnode_comp.neutron      : %s" % self.mnode_components['neutron'])
        log.debug("#     mnnode_comp.cinder       : %s" % self.mnode_components['cinder'])
        log.debug("#     mnnode_comp.glance       : %s" % self.mnode_components['glance'])        
        log.debug("#     mnnode_comp.keystone     : %s" % self.mnode_components['keystone'])
        log.debug("#     mnnode_comp.cinder_utils : %s" % self.mnode_components['cinder_utils'])
        log.debug("#     mnnode_comp.horizon_utils: %s" % self.mnode_components['horizon_utils'])
        log.debug("#     mnnode_comp.message_utils: %s" % self.mnode_components['message_utils'])
        log.debug("#     mnnode_comp.db_utils     : %s" % self.mnode_components['db_utils'])
        log.debug("")
        log.debug("# nnode_components: %s" % self.nnode_components)
        log.debug("#     nnode_components.neutron       : %s" % self.nnode_components['neutron'])
        log.debug("#     nnode_components.neutron_utils : %s" % self.nnode_components['neutron'])
        log.debug("")
        log.debug("# cnode_components: %s" % self.cnode_components)
        log.debug("#     cnode_components.nova    : %s" % self.cnode_components['nova'])
        log.debug("#     cnode_components.neutron : %s" % self.cnode_components['neutron'])
        log.debug("#     cnode_components.neutron_utils : %s" % self.cnode_components['nova_utils'])
        log.debug("#     cnode_components.neutron_utils : %s" % self.cnode_components['neutron_utils'])
    
    def remote_shell_connect(self):
        
        self.rssh = myParamiko()
        self.rssh.timeout = 10
        self.rssh.debug = True
        
        for host in self.host_list:
            # 문자열로 된 속성이름을 참조하기 위해 getattr 사용 
            node = getattr(self, host)
            log.debug("%-8s [%s] node connect" % (host, node['ip']) )
            self.rssh.register( host, node['ip'], node['port'], node['id'], node['pw'] )
            self.rssh.connect(host)

    def database_connect(self):
        
        self.db     = myRSQL()
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
            try:                 
                node = getattr(self, host)
                log.debug("%-8s [%s] node connect" % (host, node['ip']) )
            
                if host == "mnnode":
                    print "mnnode check %s" % host
                    monitor_components = self.mnnode_components
                    self.check_openstack_component(host, monitor_components, recs_ref)                    
                elif "cnode" in host:
                    print "cnode check %s" % host
                    monitor_components = self.cnode_components
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
        
        recs_json = json.dumps(recs_ref)
        log.debug(recs_json)
        
            
if __name__ == "__main__":
    
    OvsMonitor().run()
    
