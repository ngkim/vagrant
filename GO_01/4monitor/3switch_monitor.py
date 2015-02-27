#!/usr/bin/python
# -*- coding: utf-8 -*-

import os, traceback, time

import config.monitor_config  # config 정보파일을 import
import sql.sql_collection   # sql 패키지 로딩
import collections, json

from pysnmp.entity.rfc3413.oneliner import cmdgen

from helper.paramikoHelper  import myParamiko
from helper.dbHelper        import myRSQL
from helper.logHelper       import myLogger

log = myLogger(tag='switch_monitor', logdir='./log', loglevel='debug', logConsole=True).get_instance()

"""
먼저, SNMP_Port_Status()를 호출해서
switch port가 연결되어 있는 포트에 대해서만 상태정보를 구한다.

    로직::
    port_status()를 통해 현재 스위치에서 랜선이 연결된 포트리스트 추출
    연결된 포트리스트를 기준으로 다음정보를 채운다.
    1. 포트상태
    2. 포트DB
    3. 포트 traffic   
    
    ex)
    switch_port_map = {
        1: {
            'port_status': {'ifSpeed': Gauge32(1000000000), 'ifName': OctetString('Ethernet1'), 'ifType': 'ethernetCsmacd', 'ifOperStatus': 'up'}
            'traffic': {'discards': 2, 'errors': 0, 'nucast': 26, 'ucast': 99633309, 'in': 3664743575, 'out': 3883605265}
            'vlan': {
                'mac': 'e4:11:5b:d4:35:cc', 
                'vlan': 4
            },
            
        }
        .....
    }
    
"""
                        
class SNMP_Port_Status():
    
    def __init__(self, switch, ip, community):
        
        self.switch     = switch
        self.ip         = ip
        self.community  = community
        self.key = "%s-%s" % (ip, switch)
        self.enable_ports = {}
        self.enable_ports[self.key] = []

    def datafrommib(self, mib, community, ip):
        value = tuple([int(i) for i in mib.split('.')])
        generator = cmdgen.CommandGenerator()
        comm_data = cmdgen.CommunityData('server', community, 1) # 1 means version SNMP v2c
        transport = cmdgen.UdpTransportTarget((ip, 161))
    
        # LJG: getattr을 이용하여 delegate 생성
        real_fun = getattr(generator, 'nextCmd')
        res = (errorIndication, errorStatus, errorIndex, varBindTable)\
                = real_fun(comm_data, transport, value)
    
        if not errorIndication is None  or errorStatus is True:
            log.debug( "Error: %s %s %s %s" % res )
            yield None
        else:
            for varBindTableRow in varBindTable:                                        
                # data::  (ObjectName(1.3.6.1.2.1.2.2.1.5.42), Gauge32(4294967295))
                # data::  (ObjectName(1.3.6.1.2.1.31.1.1.1.1.1), OctetString('Ethernet1'))
                data  = varBindTableRow[0]
                #print "    data:: ", data
                port  = data[0]._value[len(value):]
                octets= data[1]
    
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
            # print mib
            data = self.datafrommib(mib[0], community, ip)                        
            for row in data:                
                if row:
                    #print '     row: ', row
                    
                    """
                    LJG: dict 이해하기 좋은 예
                        ports[1]['name']='leejingoo'
                        ports[1]['country']='korea'
                        >>> print ports
                        {1: {'country': 'korea', 'name': 'leejingoo'}}
                        
                        결국 위의 소스가 다음과 동일한 효과
                        ports = {
                        1 : {
                                'country': 'korea', 
                                'name': 'leejingoo'
                            }                        
                        }                        
                    """
                    ports[row['port']][mib[1]] = row['octets']                    
                else:
                    return None
        """
        print "#### port.keys ####"
        print ports.keys()        
        print "\n\n\n"
        """
        
        return ports
   
    @staticmethod
    def ifType_description(code):
        """
        
        Object      ifType
        OID         1.3.6.1.2.1.2.2.1.3Description    
                    The type of interface. Additional values for ifType are
                    assigned by the Internet Assigned Numbers Authority (IANA),
                    through updating the syntax of the IANAifType textual
                    convention.
        """
        
        map = {
                    1:'other',
                    2:'regular1822',
                    3:'hdh1822',
                    4:'ddnX25',
                    5:'rfc877x25',
                    6:'ethernetCsmacd',
                    7:'iso88023Csmacd',
                    8:'iso88024TokenBus',
                    9:'iso88025TokenRing',
                    10:'iso88026Man',
                    11:'starLan',
                    12:'proteon10Mbit',
                    13:'proteon80Mbit',
                    14:'hyperchannel',
                    15:'fddi',
                    16:'lapb',
                    17:'sdlc',
                    18:'ds1',
                    19:'e1',
                    20:'basicISDN',
                    21:'primaryISDN',
                    22:'propPointToPointSerial',
                    23:'ppp',
                    24:'softwareLoopback',
                    25:'eon',
                    26:'ethernet3Mbit',
                    27:'nsip',
                    28:'slip',
                    29:'ultra',
                    30:'ds3',
                    31:'sip',
                    32:'frameRelay',
                    33:'rs232',
                    34:'para',
                    35:'arcnet',
                    36:'arcnetPlus',
                    37:'atm',
                    38:'miox25',
                    39:'sonet',
                    40:'x25ple',
                    41:'iso88022llc',
                    42:'localTalk',
                    43:'smdsDxi',
                    44:'frameRelayService',
                    45:'v35',
                    46:'hssi',
                    47:'hippi',
                    48:'modem',
                    49:'aal5',
                    50:'sonetPath',
                    51:'sonetVT',
                    52:'smdsIcip',
                    53:'propVirtual',
                    54:'propMultiplexor',
                    55:'ieee80212',
                    56:'fibreChannel',
                    57:'hippiInterface',
                    58:'frameRelayInterconnect',
                    59:'aflane8023',
                    60:'aflane8025',
                    61:'cctEmul',
                    62:'fastEther',
                    63:'isdn',
                    64:'v11',
                    65:'v36',
                    66:'g703at64k',
                    67:'g703at2mb',
                    68:'qllc',
                    69:'fastEtherFX',
                    70:'channel',
                    71:'ieee80211',
                    72:'ibm370parChan',
                    73:'escon',
                    74:'dlsw',
                    75:'isdns',
                    76:'isdnu',
                    77:'lapd',
                    78:'ipSwitch',
                    79:'rsrb',
                    80:'atmLogical',
                    81:'ds0',
                    82:'ds0Bundle',
                    83:'bsc',
                    84:'async',
                    85:'cnr',
                    86:'iso88025Dtr',
                    87:'eplrs',
                    88:'arap',
                    89:'propCnls',
                    90:'hostPad',
                    91:'termPad',
                    92:'frameRelayMPI',
                    93:'x213',
                    94:'adsl',
                    95:'radsl',
                    96:'sdsl',
                    97:'vdsl',
                    98:'iso88025CRFPInt',
                    99:'myrinet',
                    100:'voiceEM',
                    101:'voiceFXO',
                    102:'voiceFXS',
                    103:'voiceEncap',
                    104:'voiceOverIp',
                    105:'atmDxi',
                    106:'atmFuni',
                    107:'atmIma',
                    108:'pppMultilinkBundle',
                    109:'ipOverCdlc',
                    110:'ipOverClaw',
                    111:'stackToStack',
                    112:'virtualIpAddress',
                    113:'mpc',
                    114:'ipOverAtm',
                    115:'iso88025Fiber',
                    116:'tdlc',
                    117:'gigabitEthernet',
                    118:'hdlc',
                    119:'lapf',
                    120:'v37',
                    121:'x25mlp',
                    122:'x25huntGroup',
                    123:'trasnpHdlc',
                    124:'interleave',
                    125:'fast',
                    126:'ip',
                    127:'docsCableMaclayer',
                    128:'docsCableDownstream',
                    129:'docsCableUpstream',
                    130:'a12MppSwitch',
                    131:'tunnel',
                    132:'coffee',
                    133:'ces',
                    134:'atmSubInterface',
                    135:'l2vlan',
                    136:'l3ipvlan',
                    137:'l3ipxvlan',
                    138:'digitalPowerline',
                    139:'mediaMailOverIp',
                    140:'dtm',
                    141:'dcn',
                    142:'ipForward',
                    143:'msdsl',
                    144:'ieee1394',
                    145:'if-gsn',
                    146:'dvbRccMacLayer',
                    147:'dvbRccDownstream',
                    148:'dvbRccUpstream',
                    149:'atmVirtual',
                    150:'mplsTunnel',
                    151:'srp',
                    152:'voiceOverAtm',
                    153:'voiceOverFrameRelay',
                    154:'idsl',
                    155:'compositeLink',
                    156:'ss7SigLink',
                    157:'propWirelessP2P',
                    158:'frForward',
                    159:'rfc1483',
                    160:'usb',
                    161:'ieee8023adLag',
                    162:'bgppolicyaccounting',
                    163:'frf16MfrBundle',
                    164:'h323Gatekeeper',
                    165:'h323Proxy',
                    166:'mpls',
                    167:'mfSigLink',
                    168:'hdsl2',
                    169:'shdsl',
                    170:'ds1FDL',
                    171:'pos',
                    172:'dvbAsiIn',
                    173:'dvbAsiOut',
                    174:'plc',
                    175:'nfas',
                    176:'tr008',
                    177:'gr303RDT',
                    178:'gr303IDT',
                    179:'isup',
                    180:'propDocsWirelessMaclayer',
                    181:'propDocsWirelessDownstream',
                    182:'propDocsWirelessUpstream',
                    183:'hiperlan2',
                    184:'propBWAp2Mp',
                    185:'sonetOverheadChannel',
                    186:'digitalWrapperOverheadChannel',
                    187:'aal2',
                    188:'radioMAC',
                    189:'atmRadio',
                    190:'imt',
                    191:'mvl',
                    192:'reachDSL',
                    193:'frDlciEndPt',
                    194:'atmVciEndPt',
                    195:'opticalChannel',
                    196:'opticalTransport',
                    197:'propAtm',
                    198:'voiceOverCable',
                    199:'infiniband',
                    200:'teLink',
                    201:'q2931',
                    202:'virtualTg',
                    203:'sipTg',
                    204:'sipSig',
                    205:'docsCableUpstreamChannel',
                    206:'econet',
                    207:'pon155',
                    208:'pon622',
                    209:'bridge',
                    210:'linegroup',
                    211:'voiceEMFGD',
                    212:'voiceFGDEANA',
                    213:'voiceDID',
                    214:'mpegTransport',
                    215:'sixToFour',
                    216:'gtp',
                    217:'pdnEtherLoop1',
                    218:'pdnEtherLoop2',
                    219:'opticalChannelGroup',
                    220:'homepna',
                    221:'gfp',
                    222:'ciscoISLvlan',
                    223:'actelisMetaLOOP',
                    224:'fcipLink',
                    225:'rpr',
                    226:'qam',
                    227:'lmp',
                    228:'cblVectaStar',
                    229:'docsCableMCmtsDownstream',
                    230:'adsl2',
                    231:'macSecControlledIF',
                    232:'macSecUncontrolledIF',
                    233:'aviciOpticalEther',
                    234:'atmbond'
        }
        
        if code in map:
            return map[code]
        else:
            return 'etc'
    
    @staticmethod    
    def ifOperStatus_description(code):
        """
        Object      ifOperStatus
        OID         1.3.6.1.2.1.2.2.1.8
        Type        INTEGER
        Permission  read-only
        Status      current
        Values      1 : up
                    2 : down
                    3 : testing
                    4 : unknown
                    5 : dormant
                    6 : notPresent
                    7 : lowerLayerDown        
        Description    
                    The current operational state of the interface. The
                    testing(3) state indicates that no operational packets can
                    be passed. If ifAdminStatus is down(2) then ifOperStatus
                    should be down(2). If ifAdminStatus is changed to up(1)
                    then ifOperStatus should change to up(1) if the interface is
                    ready to transmit and receive network traffic; it should
                    change to dormant(5) if the interface is waiting for
                    external actions (such as a serial line waiting for an
                    incoming connection); it should remain in the down(2) state
                    if and only if there is a fault that prevents it from going
                    to the up(1) state; it should remain in the notPresent(6)
                    state if the interface has missing (typically, hardware)
                    components.
        """
        
        map = {
            1 : 'up',
            2 : 'down',
            3 : 'testing',
            4 : 'unknown',
            5 : 'dormant',
            6 : 'notPresent',
            7 : 'lowerLayerDown'    
        }
        
        if code in map:
            return map[code]
        else:
            return 'etc'
            
    def run_debug(self):
    
        log.debug( "#"*60 )
        log.debug( "%s : %s switch port status" % (self.switch, self.ip) )
        log.debug( "#"*60 )
            
        ports = self.status(self.ip, self.community)
        
        if ports:                        
            for key, value in ports.items():                
                # ex) 1 => {'ifSpeed': Gauge32(1000000000), 'ifName': OctetString('Ethernet1'), 'ifType': Integer(6), 'ifOperStatus': Integer(1)}
                
                if value['ifOperStatus'] == 6:
                    # interface not Present
                    continue
                
                # 현재 스위치에 연결된 포트만 찾는다.    
                self.enable_ports[self.key].append(key)
                
                #log.debug( "    %s -> %s" % (value['ifOperStatus'], self.ifOperStatus_description(value['ifOperStatus'])) )
                #log.debug( "    %s -> %s" % (value['ifType'], self.ifType_description(value['ifType'])) )
                
                # code -> desc
                value['ifOperStatus'] = self.ifOperStatus_description(value['ifOperStatus'])
                value['ifType']       = self.ifType_description(value['ifType'])
                # log.debug( "%s => %s" % (key, value) )
                
                status = ( '  ' + 'port: %-8s' % key + (' ifOperStatus: %(ifOperStatus)s ifType: %(ifType)4s' +\
                            ' ifSpeed: %(ifSpeed)12s ifName: %(ifName)13s' ) % value )
                
                log.debug( status )
            
            return ports

        else:
            return []

    def run(self):
            
        ports = self.status(self.ip, self.community)
        if ports:            
            return ports
        else:
            return []
        
class SNMP_Port_Traffic():
    
    def __init__(self, switch, ip, community):
        
        self.switch     = switch
        self.ip         = ip
        self.community  = community        
    
    def datafrommib(self, mib, community, conn):
        value = tuple([int(i) for i in mib.split('.')])
        #res = (errorIndication, errorStatus, errorIndex, varBindTable)\
        #        = real_fun(comm_data, transport, value)
        res = (errorIndication, errorStatus, errorIndex, varBindTable)\
                = conn[3](conn[1], conn[2], value)
    
        if not errorIndication is None  or errorStatus is True:
            log.debug( "Error: %s %s %s %s" % res)
            yield None
        else:
            for varBindTableRow in varBindTable:
                # varBindTableRow:
                #   in: [(ObjectName(1.3.6.1.2.1.2.2.1.10.8), Counter32(180283794))]
                data = varBindTableRow[0]
                port = data[0]._value[len(value):]
                octets = data[1]
    
                yield {'port': port[0], 'octets': octets}

    def load(self, ip, community):
        # for use snmptool try:
        # In: snmpwalk -c mymypub -v2c <ip> 1.3.6.1.2.1.2.2.1.10.2
        # Out: snmpwalk -c mymypub -v2c <ip> 1.3.6.1.2.1.2.2.1.16.2
        # e.t.c...
        generator = cmdgen.CommandGenerator()
        comm_data = cmdgen.CommunityData('server', community, 1) # 1 means version SNMP v2c
        transport = cmdgen.UdpTransportTarget((ip, 161))
        real_fun = getattr(generator, 'nextCmd')
        conn = (generator, comm_data, transport, real_fun)
        mibs = [('1.3.6.1.2.1.2.2.1.16', 'out'),
                ('1.3.6.1.2.1.2.2.1.10', 'in'),
                ('1.3.6.1.2.1.2.2.1.11', 'ucast'),
                ('1.3.6.1.2.1.2.2.1.12', 'nucast'),
                ('1.3.6.1.2.1.2.2.1.13', 'discards'),
                ('1.3.6.1.2.1.2.2.1.14', 'errors')]
    
        ports = collections.defaultdict(dict)
    
        for mib in mibs:
            data = self.datafrommib(mib[0], community, conn)
            for row in data:
                if row:
                    ports[row['port']][mib[1]] = int(row['octets'])
                else:
                    return None
    
        return ports

    def run_debug(self):
        
        log.debug( "#"*60 )
        log.debug( "%s : %s switch port traffic" % (self.switch, self.ip) )
        log.debug( "#"*60 )
                
        # == debug ==
        #import profile
        #profile.run("load('%s', '%s')" % (ip, community))
        ports = self.load(self.ip, self.community)
        if ports:
            for key, value in ports.items():
                """
                ex) 1 => {'discards': 2, 'errors': 0, 'nucast': 26, 'ucast': 99261858, 'in': 3601870395, 'out': 3719859329}
                """
                
                traffic = ('in: %(in)s out: %(out)s ucast: %(ucast)s' +\
                           ' nucast: %(nucast)s discards: %(discards)s' +\
                           ' errors: %(errors)s') % value                
                #log.debug( "  %s => %s" % (key, value) )
                log.debug( "port: %3s %s" % (key, traffic) )
            return ports            
        else:
            return []
   
    def run(self):
        ports = self.load(self.ip, self.community)
        if ports:            
            return ports
        else:
            return []

class SNMP_Port_DB():
    
    def __init__(self, switch, ip, community):
        
        self.switch     = switch
        self.ip         = ip
        self.community  = community
    
    def fetchFdb(self, ip, community):
        mib     = '1.3.6.1.2.1.17.7.1.2.2.1.2'
        value   = tuple([int(i) for i in mib.split('.')])
        generator = cmdgen.CommandGenerator()
        comm_data = cmdgen.CommunityData('server', community, 1) # 1 means version SNMP v2c
        transport = cmdgen.UdpTransportTarget((ip, 161))
    
        real_fun = getattr(generator, 'nextCmd')
        res = (errorIndication, errorStatus, errorIndex, varBindTable)\
            = real_fun(comm_data, transport, value)
    
        if not errorIndication is None  or errorStatus is True:
            log.debug( "Error: %s %s %s %s" % res )
        else:
            for varBindTableRow in varBindTable:
                # varBindTableRow:
                #     [(ObjectName(1.3.6.1.2.1.17.7.1.2.2.1.2.5.0.27.144.212.92.45),Integer(27))]
                # 첫번째 요소
                #     0~12 : mib 
                #     13   : vlan
                #     14~19: mac
                # 두번째 요소
                #     int  : port
                
                data = varBindTableRow[0][0]._value[len(value):]
    
                vlan = data[0]
                #mac = '%s' % ':'.join([hex(int(i))[2:] for i in data[-6:]])
                mac = '%02x:%02x:%02x:%02x:%02x:%02x' % tuple(map(int, data[-6:]))
                port = varBindTableRow[0][1]
                yield {'port': port, 'vlan': vlan, 'mac': mac }    
            
    def run_debug(self):
    
        log.debug( "#"*60 )
        log.debug( "%s : %s switch port db" % (self.switch, self.ip) )
        log.debug( "#"*60 )
        
        port_db = []    
        for fdb in self.fetchFdb(self.ip, self.community):
            """
            ex) {'mac': 'a0:d3:c1:f2:92:9c', 'vlan': 4, 'port': Integer(2)}
            """          
            # log.debug(fdb)  
            log.debug( '  port: %(port)s vlan: %(vlan)4s mac: %(mac)s' % (fdb) ) 
            port_db.append(fdb)
            
        return port_db

    def run(self):    
        port_db = []    
        for fdb in self.fetchFdb(self.ip, self.community):
            """
            ex) {'mac': 'a0:d3:c1:f2:92:9c', 'vlan': 4, 'port': Integer(2)}
            """          
            port_db.append(fdb)
            
        return port_db
    
class SwitchMonitor(object):
    """
    Aggr Switch와 Tor Switch 모니터 정보를 수집한다.
    지금 단계에서는 간단히 폴링을 하지만 나중에는 syslog을 이용해서 
    이벤트로 받아야 하지 않을까?
    """
    
    def __init__(self):
        
        self.org_dir= os.getcwd()
        self.init_config_from_dict_config_file()        
        # self.database_connect()
        
    def __del__(self):
        
        #  데이터베이스를 정리한다.
        
        if hasattr(self, 'db'):
            self.db.finish(self.db_tag)    
        
    def init_config_from_dict_config_file(self):
        
        #
        # 데이터베이스 관련 정보
        
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
        self.switch_list = self.conf['switch_list']
        
        log.debug("#"*80)
        log.debug("# switch_list    : %s" % self.switch_list)
        
        # 감시대상 스위치
        self.aggr_sw = self.conf['aggr_sw']
        self.tor_sw  = self.conf['tor_sw']
        
        log.debug("#"*80)
        log.debug("# aggr_sw : %s" % self.aggr_sw)
        log.debug("# tor_sw  : %s" % self.tor_sw)
        
    def database_connect(self):
        
        self.db     = myRSQL()
        self.db.connect(self.db_tag, \
                        self.db_host, self.db_id, self.db_pw, self.db_name, int(self.db_port) )
    
    def analyze_port_info(self, sw, ip, port_status, port_traffic):
        
        log.debug( "#"*60 )
        log.debug( " switch name :: %s" % (sw) )
        log.debug( " switch ip   :: %s" % (ip) )
        log.debug( "#"*60 )
        
        log.debug( "  ---  switch port status  ---" )
        """
        switch_port_map[aggr_sw-221.151.188.9] = {
            1: {
                'port_status': {'ifSpeed': Gauge32(1000000000), 'ifName': OctetString('Ethernet1'), 'ifType': 'ethernetCsmacd', 'ifOperStatus': 'up'}
                'vlan': {'mac': 'e4:11:5b:d4:35:cc', 'vlan': 4, 'port': Integer(1)},
                'traffic': {'discards': 2, 'errors': 0, 'nucast': 26, 'ucast': 99633309, 'in': 3664743575, 'out': 3883605265}
            }
            .....
        }
        """
        
        present_port_list = []
        
        #
        # 전처리: 스위치 포트중에서 "present(?)" 한 포트만 추출
        
        for port_num, value in port_status.items():            
            if value['ifOperStatus'] == 6:
                # interface not Present
                continue
            # 현재 스위치에 랜선이 연결된 포트만 찾는다.    
            present_port_list.append(port_num)        
        
        
        switch_port_map = collections.OrderedDict()
        
        
        #
        # 포트상태 수집: present한 스위치 포트들에 대해서 포트정보 수집
        """
           ---  switch port status  ---
            
           1 ->  ifOperStatus: 1 ifType:    6 ifSpeed:    100000000 ifName:     Ethernet1
           2 ->  ifOperStatus: 2 ifType:    6 ifSpeed:            0 ifName:     Ethernet2
           4 ->  ifOperStatus: 2 ifType:    6 ifSpeed:            0 ifName:     Ethernet4
           5 ->  ifOperStatus: 1 ifType:    6 ifSpeed:   1000000000 ifName:     Ethernet5
           6 ->  ifOperStatus: 1 ifType:    6 ifSpeed:   1000000000 ifName:     Ethernet6
           7 ->  ifOperStatus: 1 ifType:    6 ifSpeed:   1000000000 ifName:     Ethernet7
           8 ->  ifOperStatus: 1 ifType:    6 ifSpeed:   1000000000 ifName:     Ethernet8
           9 ->  ifOperStatus: 1 ifType:    6 ifSpeed:    100000000 ifName:     Ethernet9
          10 ->  ifOperStatus: 1 ifType:    6 ifSpeed:    100000000 ifName:    Ethernet10
          11 ->  ifOperStatus: 2 ifType:    6 ifSpeed:            0 ifName:    Ethernet11
          12 ->  ifOperStatus: 1 ifType:    6 ifSpeed:    100000000 ifName:    Ethernet12
          13 ->  ifOperStatus: 2 ifType:    6 ifSpeed:            0 ifName:    Ethernet13
          14 ->  ifOperStatus: 1 ifType:    6 ifSpeed:   1000000000 ifName:    Ethernet14
          16 ->  ifOperStatus: 2 ifType:    6 ifSpeed:            0 ifName:    Ethernet16
          17 ->  ifOperStatus: 2 ifType:    6 ifSpeed:            0 ifName:    Ethernet17
          18 ->  ifOperStatus: 1 ifType:    6 ifSpeed:   1000000000 ifName:    Ethernet18
          21 ->  ifOperStatus: 1 ifType:    6 ifSpeed:   1000000000 ifName:    Ethernet21
          22 ->  ifOperStatus: 1 ifType:    6 ifSpeed:   1000000000 ifName:    Ethernet22
          23 ->  ifOperStatus: 1 ifType:    6 ifSpeed:   1000000000 ifName:    Ethernet23
          24 ->  ifOperStatus: 2 ifType:    6 ifSpeed:            0 ifName:    Ethernet24
          25 ->  ifOperStatus: 1 ifType:    6 ifSpeed:   1000000000 ifName:    Ethernet25
          26 ->  ifOperStatus: 2 ifType:    6 ifSpeed:            0 ifName:    Ethernet26
          47 ->  ifOperStatus: 1 ifType:    6 ifSpeed:   1000000000 ifName:    Ethernet47
          48 ->  ifOperStatus: 1 ifType:    6 ifSpeed:   1000000000 ifName:    Ethernet48
     2000009 ->  ifOperStatus: 1 ifType:  136 ifSpeed:            0 ifName:         Vlan9
     2000010 ->  ifOperStatus: 1 ifType:  136 ifSpeed:            0 ifName:        Vlan10
     2002000 ->  ifOperStatus: 1 ifType:  136 ifSpeed:            0 ifName:      Vlan2000
      999001 ->  ifOperStatus: 2 ifType:    6 ifSpeed:     10000000 ifName:   Management1
        
        """
        
        for port_num, value in port_status.items():
            
            if port_num in present_port_list:
                # ex) 1 => {'ifSpeed': Gauge32(1000000000), 'ifName': OctetString('Ethernet1'), 'ifType': Integer(6), 'ifOperStatus': Integer(1)}                
                            
                ifOperStatus_code = value['ifOperStatus']
                ifType_code = value['ifType']
                
                ifOperStatus_desc = SNMP_Port_Status.ifOperStatus_description(ifOperStatus_code)
                ifType_desc = SNMP_Port_Status.ifType_description(ifType_code)
                                
                status_dict = collections.OrderedDict() 
                status_dict['ifName'] = str(value['ifName'])    # OctetString 이 json serialize 안되므로 str으로 변환
                status_dict['ifType'] = ifType_desc
                status_dict['ifOperStatus'] = ifOperStatus_desc
                status_dict['ifSpeed'] = str(value['ifSpeed'])
                
                status = (' ifName: %(ifName)-13s ifType: %(ifType)-15s' +\
                          ' ifOperStatus: %(ifOperStatus)-8s ifSpeed: %(ifSpeed)11s' ) % status_dict
                 
                # print "%8s -> %s" % (port_num, status)
                
                # print status_dict
                if switch_port_map.has_key(port_num):
                    switch_port_map[port_num]['port_status'] = status_dict
                else:
                    switch_port_map[port_num] = {}
                    switch_port_map[port_num]['port_status'] = status_dict
        
        #
        # 포트 트래픽 수집: present한 스위치 포트들에 대해서 트래픽 수집
        """
        {
            1: {'discards': 151, 'errors': 0, 'nucast': 7518, 'ucast': 2343953, 'in': 372042566, 'out': 2710805534}, 
            2: {'discards': 38, 'errors': 0, 'nucast': 1436, 'ucast': 1927150101, 'in': 750742872, 'out': 3520889125}, 
            3: {'discards': 44, 'errors': 0, 'nucast': 446, 'ucast': 2, 'in': 30422, 'out': 818223823},
            ...
        }        
        """
        log.debug( "  ---  switch port traffic  ---  " )
        #log.debug( port_traffic )
        
        for port_num, value in port_traffic.items():
            
            if port_num in present_port_list:
                # ex) 1 => {'discards': 151, 'errors': 0, 'nucast': 7518, 'ucast': 2343953, 'in': 372042566, 'out': 2710805534},
                                
                traffic_dict = collections.OrderedDict() 
                traffic_dict['in']      = value['in']
                traffic_dict['out']     = value['out']                
                traffic_dict['errors']  = value['errors']
                traffic_dict['discards']= value['discards']
                traffic_dict['nucast']  = value['nucast']
                traffic_dict['ucast']   = value['ucast']
                
                traffic = (' in: %(in)13s out: %(out)13s' +\
                           ' errors: %(errors)13s discards: %(discards)13s' +\
                           ' nucast: %(nucast)13s ucast: %(ucast)13s' ) % traffic_dict
                 
                #print "%8s -> %s" % (port_num, traffic)
                
                # print status_dict
                if switch_port_map.has_key(port_num):
                    switch_port_map[port_num]['traffic_status'] = traffic_dict
                else:
                    switch_port_map[port_num] = {}
                    switch_port_map[port_num]['traffic_status'] = traffic_dict
                            
        
        return switch_port_map
        
        #        
        # 포트 DB 수집: present한 스위치 포트들에 대해서 vlan, mac과 같은 데이터 수집
        """
        ############################################################
          aggr_sw : 221.151.188.9 switch port db
        ############################################################
          vlan:   10 mac: 00:0c:29:2b:c2:6a port: 8
          vlan:   10 mac: 00:11:a9:80:5c:16 port: 8
          vlan:   10 mac: 00:15:17:48:ee:48 port: 5
          vlan:   10 mac: 00:19:af:58:09:c4 port: 8
          vlan:   10 mac: 00:1a:64:c6:ae:00 port: 8
          vlan:   10 mac: 00:1c:c0:23:1c:22 port: 8
          vlan:   10 mac: 00:1e:67:1e:6c:2f port: 23
          vlan:   10 mac: 00:24:21:54:71:8d port: 8
          vlan:   10 mac: 00:25:22:0a:42:e8 port: 8
          vlan:   10 mac: 00:50:b6:67:4c:c8 port: 8
          ....
          vlan:   11 mac: 00:11:a9:80:5c:16 port: 47
          vlan:   11 mac: 00:11:a9:82:d4:42 port: 47
          vlan:   11 mac: 00:11:a9:9d:8a:5a port: 47
          vlan:   11 mac: 00:15:17:48:ee:48 port: 8
          vlan:   11 mac: 00:18:7b:f4:c0:c3 port: 47
          vlan:   11 mac: 00:19:af:58:09:c4 port: 47
          vlan:   11 mac: 00:1a:64:c6:ae:00 port: 8
          vlan:   11 mac: 00:1c:73:4f:32:df port: 8
          vlan:   11 mac: 00:1c:c0:23:1c:22 port: 47
          vlan:   11 mac: 00:1e:67:1e:6c:2f port: 8
          vlan:   11 mac: 00:24:21:54:71:8d port: 47
          vlan:   11 mac: 00:25:22:0a:42:e8 port: 47
          ....
          vlan: 2000 mac: 00:0c:86:e7:82:4a port: 48
          vlan: 2000 mac: 00:1a:64:c6:ae:02 port: 6
          vlan: 2000 mac: 00:1c:73:4d:40:c8 port: 18
          vlan: 2000 mac: 00:26:66:53:b2:45 port: 12
          vlan: 2000 mac: 00:26:b9:37:92:ef port: 25
          vlan: 2000 mac: 44:1e:a1:61:6f:e4 port: 9
          vlan: 2000 mac: 9c:b6:54:ad:ca:36 port: 18
          vlan: 2000 mac: a0:d3:c1:f2:92:9d port: 18
          vlan: 2000 mac: d8:9d:67:18:86:41 port: 18
          vlan: 2000 mac: d8:9d:67:66:bf:44 port: 18
          vlan: 2000 mac: d8:d3:85:a5:00:44 port: 10
          vlan: 2000 mac: e4:11:5b:d4:35:ce port: 18
          vlan: 2000 mac: e4:11:5b:d4:6c:d2 port: 18
          vlan: 2000 mac: e4:11:5b:d4:d3:10 port: 1
          vlan: 2000 mac: fa:16:3e:d2:96:fe port: 18
          
        ############################################################
          tor_sw : 221.151.188.19 switch port db
        ############################################################
          vlan:    4 mac: e4:11:5b:d4:35:cc port: 1
          vlan:    4 mac: a0:d3:c1:f2:92:9c port: 2
          vlan:    4 mac: d8:9d:67:18:86:40 port: 3
          vlan: 2002 mac: fa:16:3e:04:90:45 port: 7
          vlan: 2002 mac: fa:16:3e:f2:ef:d9 port: 7  
          vlan: 2000 mac: 00:0c:86:e7:82:4a port: 9
          vlan: 2000 mac: e4:11:5b:d4:d3:10 port: 9  
          vlan: 2000 mac: e4:11:5b:d4:35:ce port: 11  
          vlan: 2000 mac: a0:d3:c1:f2:92:9d port: 12
          vlan: 2000 mac: d8:9d:67:18:86:41 port: 13
          vlan: 2000 mac: e4:11:5b:d4:6c:d2 port: 15  
          vlan: 2000 mac: 9c:b6:54:ad:ca:36 port: 16  
          vlan: 2000 mac: d8:9d:67:66:bf:44 port: 17
          vlan: 2000 mac: fa:16:3e:d2:96:fe port: 18
          vlan: 2002 mac: fa:16:3e:73:8c:fe port: 45
          vlan: 2002 mac: fa:16:3e:7e:8d:60 port: 45
          vlan: 2002 mac: fa:16:3e:b4:16:b4 port: 45
          vlan: 2002 mac: fa:16:3e:04:a6:7f port: 47
          vlan: 2002 mac: fa:16:3e:fd:fb:3a port: 47
        """
        log.debug( "  ---  switch port db  ---" )
        #log.debug( port_db )                
        
    def run(self):
        
        for switch in self.switch_list:
            sw = getattr(self, switch)
            ip = sw['ip']
            
            """
            port_status = SNMP_Port_Status(switch, ip, 'public').run_debug()
            port_db = SNMP_Port_DB(switch, ip, 'public').run_debug()                        
            port_traffic = SNMP_Port_Traffic(switch, ip, 'public').run_debug()
            """
            
            port_status = SNMP_Port_Status(switch, ip, 'public').run()
            port_traffic= SNMP_Port_Traffic(switch, ip, 'public').run()
            # port_db     = SNMP_Port_DB(switch, ip, 'public').run()
            
            #
            # 스위치의 포트번호를 기준으로 정보를 구한다.
            
            port_map = self.analyze_port_info(switch, ip, port_status, port_traffic)
            recs_json = json.dumps(port_map, indent=4, sort_keys=True)        
            log.debug( recs_json )
            
            return
            
            # return recs_json
            
            #org_dict = json.loads(recs_json)
            #print org_dict['1']
            
if __name__ == "__main__":

    SwitchMonitor().run()
    
