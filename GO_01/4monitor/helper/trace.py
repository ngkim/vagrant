#!/usr/bin/python
# -*- coding: utf-8 -*-

"""LJG: module for python function trace 
        conditional trace support
"""
import time

########################################################################
# Type 1
########################################################################
enable_tracing = True
if enable_tracing:    
    debug_log = open("log.trace", "w")    

def trace_helper(func):
    if enable_tracing:
        def callfunction(*args, **kwargs):
            debug_log.write("=> [%s] Start:: input[%s][%s]\n" % (func.__name__, args, kwargs))
            
            start = time.clock()            
            result = func(*args, **kwargs)
            elapsed = time.clock() - start
            
            debug_log.write("<= [%s] Stop :: [%0.3f]s, output[%s]\n" % (func.__name__, elapsed, result))
            
            return result
        return callfunction
    else:
        return func
        

########################################################################
# Type 2
########################################################################
#
# OUT = True
# TRACE=False
#
# def conditionally(dec, cond):
#    def resdec(f):
#        if not cond:
#            return f
#        return dec(f)
#    return resdec
#
# def mytrace(func):    
#    def callfunction(*args, **kwargs):
#        sc = time.clock()
#        print("=> [%s] Start:: input[%s][%s]\n" % (func.__name__,args,kwargs))            
#        result = func(*args, **kwargs)        
#        ec = time.clock()
#        print("<= [%s] Stop :: [%0.3f]secs,output[%s]\n" % (func.__name__, ec - sc,result))        
#        return result    
#    return callfunction

@trace_helper
def test(msg):
    print "MSG:%s" % msg
    return len(msg)

if __name__ == '__main__':
    test("!!! This module traces python program functions using decorator !!!")
