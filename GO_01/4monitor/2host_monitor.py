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

log = myLogger(tag='host_monitor', logdir='./log', loglevel='debug', logConsole=True).get_instance()

class HostMonitor(object):
    """
    클라우드를 구성하는 개별 노드의 성능정보를 수집한다.
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
        
        # 감시대상 호스트 정보 dictionary
        # prefix: m: management, n: network, c: compute, s: storage
        #         mn: mgmt & network -> controller와 network 기능을 하나의 서버에 설치(비용이슈)
        self.host_mon_commands = config.monitor_config.seocho_monitor['host_mon']
        
        log.debug("#"*80)
        log.debug("#     host cpu  status command : %s" % self.host_mon_commands['cpu'])
        #log.debug("#     host mem  status command : %s" % self.host_mon_commands['memory'])
        log.debug("#     host disk status command : %s" % self.host_mon_commands['disk'])
        log.debug("#     host net  status command : %s" % self.host_mon_commands['network'])
                    
    def remote_shell_connect(self):
        
        self.rssh = myParamiko()
        self.rssh.timeout = 10
        self.rssh.debug = True
        
        for host in self.host_list:
            log.debug( "host: %s" % host )
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
        
    def check_host_status(self, tag, host_mon_commands_dict, recs_ref):
        
        log.info("-"*80)                    
        serv_info = self.rssh.getservinfo(tag)[0]
        log.info("# Host <%s> :: %s status" % (tag, serv_info))
        log.info("-"*80)        
        
        for key, command in host_mon_commands_dict.iteritems():
            log.info("")
            log.info("# [%s] -> [%s] ::" % (key, command))
            log.debug( self.rssh.run_with_result(tag, command) )    
                
        log.info("-"*80)
        
    def run(self):
        
        recs_ref = []
        
        for host in self.host_list:                             
            try:                 
                node = getattr(self, host)
                log.debug("%-8s [%s] node connect" % (host, node['ip']) )                                
                self.check_host_status(host, self.host_mon_commands, recs_ref)                     
            
            except:                
                errmsg = "%s Error:: \n<<%s>>" % ('openstack_monitor', traceback.format_exc())            
                log.debug(errmsg)       
                raise RuntimeError(errmsg)                            
            finally:
                self.rssh.close(host)    
        
        recs_json = json.dumps(recs_ref)
        log.debug(recs_json)            
            
if __name__ == "__main__":
    
    HostMonitor().run()
    
