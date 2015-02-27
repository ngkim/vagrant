#!/usr/bin/python
# -*- coding: utf-8 -*-

import httplib
import xmlrpclib
import os, sys, traceback

     
class TimeoutHTTPConnection(httplib.HTTPConnection):
    def __init__(self, host, timeout=2):
        """Timeout http connection"""
        httplib.HTTPConnection.__init__(self, host, timeout=timeout)


class TimeoutTransport(xmlrpclib.Transport):

    def __init__(self, timeout=2, *l, **kw):
        """Timeout xmlrpc transport"""
        # LJG: 파이썬 2.4버전에서 xmlrpc timeout 설정을 위해서는 
        # 현재로서는 socket global timeout 밖에는 없다.
        # ex) socket.setdefaulttimeout(2)
                    
        self.timeout = timeout        
        xmlrpclib.Transport.__init__(self, *l, **kw)        

    def make_connection(self, host):
        """Make connection with timeout"""
        if sys.version_info < (2, 5):
            # conn = httplib.HTTP(host, timeout=self.timeout)
            conn = httplib.HTTPConnection(host, timeout=self.timeout)
        else:
            conn = TimeoutHTTPConnection(host, self.timeout)
        
        return conn
        
################################################################################




if __name__ == '__main__':

    # needs for test
    from baseServer import (ForkingSimpleXMLRPCServer,
                            ThreadingSimpleXMLRPCServer)
    from utility    import (ThreadInfo, ProcessInfo)
    from wireprotocol import (OrderedMap, make_tag,
                             request_format, request_parse,
                             response_format, response_parse)
    from utility    import exec_cmd
    import threading
    
    
    rpc_port = 8889

    def server_start(serv_concurrent='thread'):
    
        def process_status(request):
            """LJG: Manager가 동작하는 프로세스의 자체 상태를 유닉스 명령을 이용해서 보여준다"""
            result = {}
            cmd = "ps aux -L |grep %s |grep -v grep" % ('baseClient')
            try:
                
                proc_stat = exec_cmd(cmd, inputtext=None)
                result['StatusUnixCommand'] = cmd
                result['StatusByCommand'] = proc_stat
            
                thread_stat = ThreadInfo().getThreadEnumerate()
                thread_stat.sort()
                result['StatusByThreadInfo'] = "ThreadNUM [%s] \n%s" % (len(thread_stat), thread_stat)
                
            except Exception:            
                errmsg = "%s Error:: \n<<%s>>" % ('baseServer.process_status', traceback.format_exc())            
                print(errmsg)
                response = response_format('baseServer.process_status', False, errmsg)
            else:
                response = response_format('baseServer.process_status', True, result)
            
            return response 
        # # end of process_status()
        
        
        serv_ip = 'localhost'
        serv_port = rpc_port
        
        print "########################## SERVER SIDE ##########################"
        print "XmlRpcServer[%s/%s] <<%s>> Starting ....." % (serv_ip, serv_port, serv_concurrent)
        try:        
                            
            if serv_concurrent == 'process':
                print "    Process Mode로 시작"
                Server = ForkingSimpleXMLRPCServer
            else:
                print "    Thread Mode로 시작"
                Server = ThreadingSimpleXMLRPCServer            
            serv = Server(
                        (serv_ip, serv_port), logRequests=False
                    )
            
             
            serv.register_function(process_status)         
            serv.register_introspection_functions()
            print "    -> process_status register"  
            # print "    -> 내부테스트 ", process_status('anything')
            
            serv.serve_forever()
                
        except Exception:
            errmsg = "SimpleXMLRPCServer(%s/%s) Error:: \n<<%s>>" % (serv_ip, serv_port, traceback.format_exc())            
            print errmsg   
        else:
            print "XmlRpcServer[%s/%s] Start Succ !!!!!" % (serv_ip, serv_port)
        print "########################## SERVER SIDE ##########################"         
    # # end of server_start()
        
    def client_start(timeout=5):
        
        print "########################## CLIENT SIDE ##########################"
        
        rpcserv = 'localhost'
        rpcport = rpc_port
        try:
            
            
            
            if sys.version_info < (2, 5):
                import socket
                rpc_server = xmlrpclib.ServerProxy("http://%s:%d" % (rpcserv, rpcport), verbose=False)
                socket.setdefaulttimeout(2)
            else:
                tt = TimeoutTransport(timeout=timeout)
                rpc_server = xmlrpclib.ServerProxy("http://%s:%d" % (rpcserv, rpcport), transport=tt, verbose=False)
                
            print("    Xmlrpclib.ServerProxy(http://%s:%d) Created" % (rpcserv, rpcport))        
            print("    Xmlrpc server support modules like follows:: ")
            
            for module in rpc_server.system.listMethods():
                print("    -> " + module)            
            
            hostname = ProcessInfo.getHostName()
            tag = make_tag(hostname, 'rpc_client_test')
            enc_request_map = request_format(tag, 'get_server_process_thread_statas')            
            
            enc_result = rpc_server.process_status(enc_request_map)                    
            (succ, result) = response_parse(enc_result)
            
            if succ:
                print "##########################################"
                print "# SUCC :: get_server_process_thread_statas"
                OrderedMap.detail_print(result)
            else:
                print "##########################################"
                print "# FAIL :: get_server_process_thread_statas" + result 
    
        except Exception:
            errmsg = "baseClient RpcClient Test Error :: \n[%s]" % (traceback.format_exc())
            print(errmsg)
        
        print "########################## CLIENT SIDE ##########################" 
    # # end of client_start()
    
    
    # 서버를 먼저 실행, 반드시 쓰레드나 다른 프로세스로 실행해야 함.    
    serv_thread = threading.Thread(target=server_start, args=('thread',))
    serv_thread.daemon = True
    serv_thread.name = 'XmlRpcServer'
    serv_thread.start()                

    print "  # thread.getName()", serv_thread.getName()
    print "  # thread_ident()", str(serv_thread.get_ident())
    
    # 클라이언트 실행
    import time
    time.sleep(1)
    
    client_start(timeout=5)
