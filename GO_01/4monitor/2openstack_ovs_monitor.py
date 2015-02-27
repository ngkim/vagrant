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

log = myLogger(tag='parse_div_info_and_save', logdir='./log', loglevel='debug', logConsole=True).get_instance()

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
        


import sys
import collections
from pysnmp.entity.rfc3413.oneliner import cmdgen
    
class TorMonitor(object):
    """
    Aggr Switch와 Tor Switch 모니터 정보를 수집한다.
    지금 단계에서는 간단히 폴링을 하지만 나중에는 syslog을 이용해서 
    이벤트로 받아야 하지 않을까?
    """
    
    def __init__(self):
        
        self.org_dir= os.getcwd()
        self.init_config_from_dict_config_file()
        
        self.database_connect()
        #self.remote_shell_connect()
        
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
        # 감시대상 스위치 정보
        """    
            * SNMP 활성화 및 SNMP Community 생성
            - AGGR SW와  TOR SW에 동일하게 SNMP 설정
            - SNMP community
               1) public (read-only)
               2) private (read-write)
            
            AGGR-SWITCH(config)#snmp-server community public ro
            AGGR-SWITCH(config)#snmp-server community private rw
            AGGR-SWITCH(config)#end
            AGGR-SWITCH#wr m
            Copy completed successfully.
            
            * 설정 확인
            snmpwalk -v2c -c public -On 221.151.188.9
            
            root@controller:~# snmpwalk -v2c -c public 221.151.188.9 iso.3.6.1.2.1.1.5.0 iso.3.6.1.2.1.1.5.0 = STRING: "AGGR-SWITCH"
            
            root@controller:~# snmpwalk -v2c -c public 221.151.188.19 iso.3.6.1.2.1.1.5.0 iso.3.6.1.2.1.1.5.0 = STRING: "TOR-SWITCH"            
        """
    
        # 감시대상 스위치 리스트
        self.switch_list = config.monitor_config.seocho_monitor['switch_list']
        
        log.debug("#"*80)
        log.debug("# switch_list    : %s" % self.switch_list)
        
        # 감시대상 스위치
        self.aggr_sw = config.monitor_config.seocho_monitor['aggr_sw']
        self.tor_sw  = config.monitor_config.seocho_monitor['tor_sw']
        
        log.debug("#"*80)
        log.debug("# aggr_sw : %s" % self.aggr_sw)
        log.debug("# tor_sw  : %s" % self.tor_sw)
        
    def database_connect(self):
        
        self.db     = myRSQL()
        self.db.connect(self.db_tag, \
                        self.db_host, self.db_id, self.db_pw, self.db_name, int(self.db_port) )
        
    
    def datafrommib(self, mib, community, ip):
        value = tuple([int(i) for i in mib.split('.')])
        generator = cmdgen.CommandGenerator()
        comm_data = cmdgen.CommunityData('server', community, 1) # 1 means version SNMP v2c
        transport = cmdgen.UdpTransportTarget((ip, 161))
    
        real_fun = getattr(generator, 'nextCmd')
        res = (errorIndication, errorStatus, errorIndex, varBindTable)\
                = real_fun(comm_data, transport, value)
    
        if not errorIndication is None  or errorStatus is True:
               print "Error: %s %s %s %s" % res
               yield None
        else:
            for varBindTableRow in varBindTable:
                data = varBindTableRow[0]
                port = data[0]._value[len(value):]
                octets = data[1]
    
                yield {'port': port[0], 'octets': octets}
    
    def status(self, ip, community):
        # for use snmptool try:
        # snmpwalk -c mymypub -v2c <ip> <mib>
        # e.t.c...
        mibs = [('1.3.6.1.2.1.2.2.1.8', 'ifOperStatus'),
                ('1.3.6.1.2.1.2.2.1.3', 'ifType'),
                ('1.3.6.1.2.1.2.2.1.5', 'ifSpeed'),
                ('1.3.6.1.2.1.31.1.1.1.1', 'ifName')                
                ]
                #('1.3.6.1.2.1.31.1.1.1.18', 'ifAlias')
    
        ports = collections.defaultdict(dict)
    
        for mib in mibs:
            data = self.datafrommib(mib[0], community, ip)
            for row in data:
                if row:
                    ports[row['port']][mib[1]] = row['octets']
                else:
                    return None
    
        return ports
    
    def port_status(self, switch, ip, community):
    
        ports = self.status(ip, community)
        if ports:
            print "#"*60
            print "%s : %s switch port status" % (switch, ip)
            print "#"*60
            
            for key, value in ports.items():
                 
                print '  ', '%8s' % key, ('ifOperStatus: %(ifOperStatus)s ifType: %(ifType)4s' +\
                            ' ifSpeed: %(ifSpeed)12s ifName: %(ifName)13s' ) % value
                """            
                print '  ', '%8s' % key, ('ifOperStatus: %(ifOperStatus)s ifType: %(ifType)4s' +\
                            ' ifSpeed: %(ifSpeed)12s ifName: %(ifName)13s' +\
                            ' ifAlias: %(ifAlias)s') % value
                """
    
    def fetchFdb(self, ip, community):
        mib = '1.3.6.1.2.1.17.7.1.2.2.1.2'
        value = tuple([int(i) for i in mib.split('.')])
        generator = cmdgen.CommandGenerator()
        comm_data = cmdgen.CommunityData('server', community, 1) # 1 means version SNMP v2c
        transport = cmdgen.UdpTransportTarget((ip, 161))
    
        real_fun = getattr(generator, 'nextCmd')
        res = (errorIndication, errorStatus, errorIndex, varBindTable)\
            = real_fun(comm_data, transport, value)
    
        if not errorIndication is None  or errorStatus is True:
               print "Error: %s %s %s %s" % res
        else:
            for varBindTableRow in varBindTable:
                # varBindTableRow:
                #     [(ObjectName(1.3.6.1.2.1.17.7.1.2.2.1.2.5.0.27.144.212.92.45),
                #     Integer(27))]
    
                data = varBindTableRow[0][0]._value[len(value):]
    
                vlan = data[0]
                #mac = '%s' % ':'.join([hex(int(i))[2:] for i in data[-6:]])
                mac = '%02x:%02x:%02x:%02x:%02x:%02x' % tuple(map(int, data[-6:]))
                port = varBindTableRow[0][1]
                yield {'vlan': vlan, 'mac': mac, 'port': port}
    
    def port_db(self, switch, ip, community):
        
        print "#"*60
        print "%s : %s switch port db" % (switch, ip)
        print "#"*60
            
        for fdb in self.fetchFdb(ip, community):
            #print fdb
            print '  vlan: %(vlan)4s mac: %(mac)s port: %(port)s' % (fdb)
    

    def run(self):
        
        for switch in self.switch_list:
            sw = getattr(self, switch)
            ip = sw['ip']
            
            print "\n\n"
            self.port_status(switch, ip, 'public')
            print
            self.port_db(switch, ip, 'public')
            
            
if __name__ == "__main__":
    
    OpenStackMonitor().run()
    TorMonitor().run()
    
