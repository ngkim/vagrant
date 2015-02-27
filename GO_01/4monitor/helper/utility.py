#!/usr/bin/env python
# -*- coding: utf-8 -*-

import threading
import os, sys, traceback
import subprocess
import time, datetime
import __main__  # for process file name
import inspect  # for stack print
import platform
import socket

#############################################################################
# utility functions
#############################################################################            

def process_name():
    return __main__.__file__

def str_datetime(mode='basic'):
    """
    지금 시각을 '%Y-%m-%d %H:%M:%S %Z'포맷으로 돌려준다. 
    
    time.strftime("%Y-%m-%d %H:%M:%S %Z", time.localtime(time.time()))
    now = time.localtime(time.time())    
    print time.strftime("%y/%m/%d %H:%M", now)
    print time.strftime("%a %b %d", now)
    print time.strftime("%c", now)
    print time.strftime("%I %p", now)
    print time.strftime("%Y-%m-%d %H:%M:%S %Z", now)
    """
    if mode == 'basic':
        return time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
    else:
        return str(datetime.datetime.now()) 

def exec_cmd(cmd, inputtext=None):
    """run shell command on *unix/windows"""
    
    if platform.system() == 'Windows':
        proc = subprocess.Popen(cmd,
            stdin=subprocess.PIPE, \
            stdout=subprocess.PIPE, \
            stderr=subprocess.PIPE, \
            shell=True)
    else:  
        proc = subprocess.Popen(cmd,
            stdin=subprocess.PIPE, \
            stdout=subprocess.PIPE, \
            stderr=subprocess.PIPE, \
            shell=True, \
            close_fds=True)
        
    (response, error) = proc.communicate(inputtext)            
    if error != '':
        raise RuntimeError("[%s] command Error \n[%s]" % (cmd, error))
    else:
        return response

def kill_previous_process(process_name, mypid):
    """
    process_name에 해당하는 프로세스를 죽인다.    
        ex) 다음과 같으면 5560, 5711 을 죽인다.
        kill_previous_process('manager_starter.py')
        root      5560     1  6 Nov12 ?        00:54:04 python2.7 manager_starter.py
        root      5711  5560  0 Nov12 ?        00:00:00 [python2.7] <defunct>
    만약, mypid가 설정되어 있으면 그 프로세스는 제외하고 죽인다.
    """
    
    # 이 모듈을 호출하는 프로세스는 삭제하면 안되므로 제외
    print "my pid [%s]" % mypid   
    cmd = """ps -ef | grep %s | grep -v grep | awk '{print $2}' | grep -v %s | xargs kill -9""" % (process_name, mypid)
        
    try:        
        exec_cmd(cmd)
    except Exception, error:
        errmsg = "%s %s kill_previous_process Error::\ncmd[%s]\n<<%s>>!!!" % (str_datetime(), process_name, cmd, error)
        return errmsg
    else:
        result = "%s %s kill_previous_process Succ::\ncmd[%s]" % (str_datetime(), process_name, cmd)
        return result

def check_previous_process(process_name, mypid):
    # process_name 관련 모든 프로세스를 죽인다.            
    cmd = """ps -ef | grep %s | grep -v grep | grep -v %s | wc -l""" % (process_name, mypid)
    print "cmd[%s]" % cmd    
    try:        
        result = int(exec_cmd(cmd).strip())
    except Exception, error:
        errmsg = "%s %s check_previous_process Error::\ncmd[%s]\n<<%s>>!!!" % (str_datetime(), process_name, cmd, error)
        print errmsg
        return False
    else:
        print "result[%s]" % result
        if result > 0:
            return True
        else:
            return False

def check_previous_processbyport(port):        
    """
    주어진 포트를 사용하는 프로세스가 있으면  True, 없으면 False
    """
    cmd = "netstat -naop | egrep '(%s)'|grep LISTEN|grep -v grep| wc -l" % port
    print "cmd[%s]" % cmd
    try:
        result = int(exec_cmd(cmd).strip())
    except Exception, error:
        errmsg = "%s %s check_previous_process_port Error::\ncmd[%s]\n<<%s>>!!!" % (str_datetime(), process_name, cmd, error)
        print errmsg
        return False
    else:
        if result > 0:
            return True
        else:
            return False
                    
def xen_version(hostname):
    return
    """cnode에 설치된 xen version 정보를 구한다"""
    
#     cmd = """xe host-param-get uuid=`xe host-list name-label=%s params=uuid --minimal` param-name=software-version param-key=product_version""" % (hostname)
#     
#     try:
#         xen_version = exec_cmd(cmd)
#     except Exception, error:
#         print "###"
#         print " %s xen_version Error <<%s>>!!!" % (str_datetime(), error)
#         print "###"
#         return 'Not Known'
#     else:
#         return str(xen_version).strip()

def python_version():
     
    # if sys.version_info < (2, 4):
    #     raise "must use python 2.5 or greater"
    
    return sys.version_info

def python_object_size_enumerate():    
    import decimal
    
    d = {
        "int":      0,
        "float":    0.0,
        "dict":     dict(),
        "set":      set(),
        "tuple":    tuple(),
        "list":     list(),
        "str":      "a",
        "unicode":  u"a",
        "decimal":  decimal.Decimal(0),
        "object":   object(),
    }
    
    for k, v in sorted(d.iteritems()):
        print "    %8s -> %s" % (k, sys.getsizeof(v))

def str2raw(in_str):
    """Returns a raw string representation of text"""
    
    escape_dict = {
            '\a':r'\a',
            '\b':r'\b',
            '\c':r'\c',
            '\f':r'\f',
            '\n':r'\n',
            '\r':r'\r',
            '\t':r'\t',
            '\v':r'\v',
            '\'':r'\'',
            '\"':r'\"',
            '\0':r'\0',
            '\1':r'\1',
            '\2':r'\2',
            '\3':r'\3',
            '\4':r'\4',
            '\5':r'\5',
            '\6':r'\6',
            '\7':r'\7',
            '\8':r'\8',
            '\9':r'\9'
        } 
    
    out_str = ''
    text = str(in_str)
    for char in text:
        try: 
            out_str += escape_dict[char]
        except KeyError: 
            out_str += char
            
    return out_str    
        
def script_dir():
    """현재 실행되는 스크립트가 동작하는 디렉토리"""
    
    script_dir = os.path.dirname(inspect.stack()[-1][1])    
    
    print "script_dir :: " , script_dir

def show_stack():
    """현재 동작하는 스텍의 내용을 추출"""    
    stack = inspect.stack()
    for s in stack:
        print s
        
    for s in stack:
        print 'objectid:', s[0]
        print 'filename:', s[1]
        print 'line    :', s[2]
        print 'co_name :', s[3]
        print 'context :', s[4]
        print


enable_tracing = True
def trace(func):    
    
    if enable_tracing:
        def callf(*args, **kwargs):
            print("#Calling %s: %s, %s" % (func.__name__, args, kwargs))
            r = func(*args, **kwargs)
            print("#%s returned %s\n" % (func.__name__, r))
            return r
        return callf
    else:
        return func    


#############################################################################
# utility classes
#############################################################################            
class EnvInfo(object):    
    def __str__(self):      
        line = "#"*80 + '\n'  
        line += "  EnvInfo\n"
        line += "-"*80 + '\n'
        line += "    os.name    :: [%s]\n" % os.name
        line += "    os.curdir  :: [%s]\n" % os.curdir
        line += "    os.defpath :: [%s]\n" % os.defpath
        line += "    os.environ ::\n"
        for key, val in os.environ.iteritems():
            line += "    %30s :: [%s]\n" % (key, val)
        return line

class ProcessInfo(object):
    """다양한 프로세스관련 정보를 구한다"""
    
    @staticmethod
    def getHostName():        
        return socket.gethostname()
    
    @staticmethod
    def getHostIp():        
        try:
            hostip = socket.gethostbyname(socket.gethostname())
        except Exception, error:
            print error
            print "FAIL:: socket.gethostbyname(socket.gethostname())"
            return socket.gethostname()
        else:
            return hostip
            
    @staticmethod
    def getProcessName():        
        return __main__.__file__
    
    @staticmethod
    def getPID():
        return os.getpid()
    
    def __str__(self):        
        line = "#"*80 + '\n' 
        line += "  ProcessInfo\n"
        line += "-"*80 + '\n'               
        line += "    process id   :: [%s]\n" % self.getPID()              
        line += "    process name :: [%s]\n" % self.getProcessName()
        return line
    
class ThreadInfo(object):
    """다양한 쓰레드관련 정보를 구한다"""
    
    @staticmethod
    def getThreadCurrent():        
        if sys.version_info < (2, 7):
            print "Not Supported under 2.7 !!"
            return threading.enumerate()
        else:
            return threading.current_thread()
        
    @staticmethod    
    def getThreadName():
        
        if sys.version_info < (2, 7):
            print "Not Supported under 2.7 !!"
            return threading.enumerate()            
        else:
            return threading.current_thread().name
    
    @staticmethod
    def getThreadActiveCount():
        if sys.version_info < (2, 7):
            return len(threading.enumerate())
            # return "Not Supported under 2.7 !!"
        else:
            return threading.active_count()
    
    @staticmethod
    def getThreadEnumerate():
        return threading.enumerate()
    
    @staticmethod
    def getThreadLocal():
        return threading.local
    
    def __str__(self):        
        line = "#"*80 + '\n'
        line += "  ThreadInfo\n"
        line += "-"*80 + '\n'                
        line += "    thread_count   :: [%s]\n" % self.getThreadActiveCount() 
        line += "    current_thread :: [%s]\n" % self.getThreadCurrent() 
        line += "    thread_list    ::\n"
        i = 1
        for ti in self.getThreadEnumerate():
            line += "                 %d -> [%s] \n" % (i, str(ti))
            i += 1
        
        line += "#"*80 + '\n'
        
        return line

class RunTimer(object):
    """
    일정 주기로 동작을 수행하는 클래스
    동작을 수행할 때 마다 새로운 쓰레드를 만들어서 수행하므로 
    쓰레드 생성 및 정리 부하가 있다
    """

    maxnum = 0
    curnum = 0

    def __init__(self, interval, func, *args, **kwargs):
        self._timer = None
        self.interval = interval
        self.function = func
        self.args = args
        self.kwargs = kwargs
        self.is_running = False
        # self.start()

    def check(self):
        self.curnum += 1
        
        # 0이면 무한루프
        if self.maxnum == 0:
            return True
        
        if self.curnum > self.maxnum:
            self.curnum = 0
            return False
        
        return True


    def _run(self):
        """
            notice!!!
              함수를 호출하는 순서가 중요
            
            case1) 
                function()
                start()
            case2) 
                start()
                function()
            
            case1) 
                동작: sequential loop 실행
                장점: sequential 하게 동작하므로 쓰레드 safe하다
                단점: function()수행시간이 길어지면 의도했던 간격으로 동작하지 않고 실행시간이 계속 밀린다.
            case2) 
                동작: 쓰레드가 정확한 간격으로 루프 실행, 동시에 여러개의 쓰레드 실행가능
                장점: 정확한 간격의 시간에 개별 쓰레드를 실행하여 동작하므로 의도했던 시간간격에 정확히 작업이 진행된다.
                단점: function()수행이 길고 간격이 짧으면 function()수행이 다중쓰레드 환경에 노출되므로
                   thread safe 하지 않아서 쓰레드간의 공유리소스가 있으면 충돌에러가 발생한다.            
        """
        
        try:
        
            self.is_running = False        
            self.function(*self.args, **self.kwargs)
        
        except Exception:            
            errmsg = "#"*60
            errmsg += "\n# utility.RunTimer._run Error :: \n[%s]\n" % (traceback.format_exc())
            errmsg += "#"*60
            print errmsg
            
        self.start()

    def start(self):
        
        if not self.check():
            self.stop()
            return
         
        if not self.is_running:
            self._timer = threading.Timer(self.interval, self._run)
            self._timer.start()
            self.is_running = True

    def stop(self):
        self._timer.cancel()
        self.is_running = False

# end of class

        
if __name__ == '__main__':
    
    print '# str_datetime test'    
    cur_dt = str_datetime()
    print cur_dt
    
    print '# exec_cmd test'    
    if platform.system() == 'Windows':
        cmd = 'dir'
    else:      
        cmd = 'ls -al'
        
    response = exec_cmd(cmd)
    print response
    
    print "# python environment info print test"
    print EnvInfo()
    
    print "# python process info print test"
    print ProcessInfo()             
    
    print "# python thread info print test"
    print ThreadInfo()   
    
    print "# python stack show test"
    show_stack()
    
    print "# python str2raw 변환 test"
    print str2raw("\str'2'raw")  # -> \str\'2\'raw
    
    print "# python_object_size_enumerate print test"
    python_object_size_enumerate()    
    
    print "# python timer test"
    _cnt = 1    
    def callbackByTimer(msg, *args, **kwargs):
        global _cnt
                        
        th = threading.currentThread()
        
        print "%d] %s" % (_cnt, msg)
        _cnt += 1
        print "    time :: ", str_datetime()
        print "    thread info -> ", th
        print "    thread id   -> ", id(th)              
        
    rt = RunTimer(1, callbackByTimer, 'jingooTimer')
    rt.start()
    
    
