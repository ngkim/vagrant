#!/usr/bin/python -B
# -*- coding: utf-8 -*-

import sys, os
import traceback
import logging
from logging import handlers

"""
(notice) python logging package 출력 우선순위 설정 방법
1. logger.setLevel 에 의해 설정되는 것이 우선순위가 가장 높다
    즉, logger에서 INFO로 설정하면 하부 loghandler에서 DEBUG로 설정해도 
    DEBUG 모드는 출력이 안된다.
2. 위처럼 최상위 logger이 DEBUG로 설정되어 있으면 하부 handler에서 옵션 설정이 가능한다
    console은 INFO, file은 DEBUG로 설정하면
    console 출력은 info에 해당되는 메시지만 보고
    file 출력은 debug까지 상세한 정보를 볼수 있다.
"""

                    
# logging.basicConfig(level = logging.INFO,
#                    format="%(asctime)s [%(funcName)s:%(lineno)03d] %(levelname)-5s: %(message)s",
#                    datefmt="%m-%d-%Y %H:%M:%S",
#                    stream = sys.stdout)


class myLogger():
    def __init__(self, tag, logdir, loglevel, logConsole=True):
        self.tag    = tag
        self.logdir = logdir
        
        self.log_fname     = "%s.log" % (tag)
        self.errlog_fname  = "%s.err" % (tag)        
        
        # print "logdir: %s" % logdir
        
        import inspect
        script_dir = os.path.dirname(inspect.stack()[-1][1])
        #print "script_dir <%s>" % script_dir
        logdir = os.path.join(script_dir, 'log')            
            
        if os.path.exists(logdir):
            # print "%s dir exists"  % logdir
                        
            self.filelog_file_path = os.path.join(logdir, self.log_fname)
            self.errlog_file_path  = os.path.join(logdir, self.errlog_fname)
        else:
            #print "%s dir non-exists" % logdir
            
            try:
                os.makedirs(logdir)
            except Exception, err:
                print err
                
            self.filelog_file_path = os.path.join(logdir, self.log_fname)
            self.errlog_file_path  = os.path.join(logdir, self.errlog_fname)
        
        self.logger = logging.getLogger(tag)
        
        # LJG: 여기에 설정된 수준 이상의 로그만 출력
        if loglevel == "debug":            
            self.logger.setLevel(logging.DEBUG)          
        elif loglevel == "info":            
            self.logger.setLevel(logging.INFO)
        elif loglevel == "error":            
            self.logger.setLevel(logging.ERROR)
        elif loglevel == "debug":            
            self.logger.setLevel(logging.CRITICAL)
        else:            
            self.logger.setLevel(logging.INFO)
            
        self.set_error_log_env(self.errlog_file_path)
        self.set_file_log_env(self.filelog_file_path)
        
        if logConsole:
            self.set_console_log_env()       
    
    def get_instance(self):
        return self.logger
    
    def set_error_log_env(self, logfile):
        
        # 메시지 포맷 설정
        errfmt = logging.Formatter("%(asctime)s [%(process)s/%(threadName)s/%(funcName)s:%(lineno)03d] %(levelname)-5s: %(message)s")
        
        # ERROR 수준의 메시지를 log.error 파일에 출력하는 처리기
        maxbytes = 100000000  # 100M
        error_handler = handlers.RotatingFileHandler(logfile, maxBytes=maxbytes, backupCount=5)
        error_handler.setLevel(logging.ERROR)
        error_handler.setFormatter(errfmt)
    
        # error만 따로 출력
        self.logger.addHandler(error_handler)

    def set_file_log_env(self, logfile):
        # 
        # 메시지를 파일에 출력하는 처리기
        stdfmt = logging.Formatter("%(asctime)s %(levelname)-5s: %(message)s")
        maxbytes = 100000000  # 100M
        filelog_handler = handlers.RotatingFileHandler(logfile, maxBytes=maxbytes, backupCount=5)
        #filelog_handler = handlers.TimedRotatingFileHandler(logfile, when="midnight", backupCount=5)
        filelog_handler.setFormatter(stdfmt)
             
        self.logger.addHandler(filelog_handler)
    
    def set_console_log_env(self):
        # 
        # stdout console에 출력하는 처리기
        stdfmt = logging.Formatter("%(asctime)s %(levelname)-5s: %(message)s")
        stdout_handler = logging.StreamHandler(sys.stdout)
        stdout_handler.setFormatter(stdfmt)
        self.logger.addHandler(stdout_handler)

if __name__ == '__main__':    

    log = myLogger(tag='ljg', logdir='./log', loglevel='debug', logConsole=True).get_instance()
    
    log.debug("debug message %s" % "디버그 메시지")
    log.info("info message %s" % "정보 메시지")    
    log.propagate = False    
    log.error("error message %s" % "에러 메시지1")        
    log.propagate = True    
    log.error("error message %s" % "에러 메시지2")
    kw = {'key':'val','key1':'val2'}
    log.debug("debug kw %s", kw)     
    
    
