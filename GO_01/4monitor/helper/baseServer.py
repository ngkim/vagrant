#!/usr/bin/python
# -*- coding: utf-8 -*-

"""LJG: master xmlrpc server에서 사용할 XmlRpcServer Template
    - ForkingSimpleXMLRPCServer
    - ThreadingSimpleXMLRPCServer
    - 
"""

# 개별 모듈을 쓰레드로 동작시키기 위해 필요
import os
import threading
from SimpleXMLRPCServer import (SimpleXMLRPCServer,
                                SimpleXMLRPCRequestHandler)
from SocketServer import ThreadingMixIn
from SocketServer import ForkingMixIn

class ForkingSimpleXMLRPCServer(ForkingMixIn, SimpleXMLRPCServer):
    """xmlrpc server customize sample
    -> process로 concurrent 처리, 단 jython을 fork 지원안함. 쓰레드 처리 필요 
    """ 
    # 관리망이므로 10초면 충분 
    timeout = 10
    
    # 소켓포트는 항상 재사용 허용
    allow_reuse_address = True
    
    # 최대 10개의 프로세스 사용, 디폴트는 40인듯...
    max_children = 10
    
#    def verify_request(self, request, client_address):
#        host, port = client_address
#        print("# PID[%s] => Client[%s/%s] Process" % (os.getpid(), host, port))
#        if host != '127.0.0.1':
#            pass
#            #return False        
#        else:
#            pass
#        
#        return SimpleXMLRPCServer.verify_request(self, request, client_address)
    
class ThreadingSimpleXMLRPCServer(ThreadingMixIn, SimpleXMLRPCServer):
    """xmlrpc server customize sample
    -> process로 concurrent 처리, 단 jython을 fork 지원안함. 쓰레드 처리 필요 
    """
    
    # 관리망이므로 10초면 충분 
    timeout = 10
    
    # 소켓포트는 항상 재사용 허용
    allow_reuse_address = True
    
    # 최대 10개의 쓰레드 사용, 디폴트는 40인듯...
    max_children = 10
    
#    def verify_request(self, request, client_address):
#        host, port = client_address
#        
#        #log.debug("# Active Thread Count [%s]" % (threading.activeCount()))        
#        #log.debug("# TID[%s] => Client[%s/%s] Process" % (threading.currentThread(), host, port))
#        
#        if host != '127.0.0.1':
#            pass
#            return False        
#        else:
#            pass        
#        return SimpleXMLRPCServer.verify_request(self, request, client_address)

class MaxSizeXMLRPCRequestHandler(SimpleXMLRPCRequestHandler):
    """xmlrpc server의 request-handler customize sample
    -> client의 데이터 사이즈 검사기를 도입 
    """ 
    MAXSIZE = 1024 * 1024  # 1MB    
    
    def do_POST(self):
        print("Header::     <<", self.headers, ">>")
        print("RequestLine: <<", self.requestline, ">>")
        
        size = int(self.headers.get('content-length', 0))
        
        if size >= self.MAXSIZE:
            self.send_error(400, "Bad Request: Too Big Data <%d>bytes" % size)
        else:
            SimpleXMLRPCRequestHandler.do_POST(self)   











if __name__ == '__main__':

    # needs for test
    from baseClient import (TimeoutTransport)
    from utility    import (ThreadInfo, ProcessInfo)
    from wireprotocol import (OrderedMap, make_tag,
                             request_format, request_parse,
                             response_format, response_parse)
    from utility    import exec_cmd
    import threading
    import xmlrpclib
    import os, sys, traceback
    
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
            
            tt = TimeoutTransport(timeout=timeout)
            rpc_server = xmlrpclib.ServerProxy("http://%s:%d" % (rpcserv, rpcport), transport=tt, verbose=True)
            
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
    
    # 클라이언트 실행
    import time
    time.sleep(1)
    
    client_start(timeout=5)
