# -*- coding: utf-8 -*-

"""
- 프로그램 사이의 원격통신은 다음 구조를 따른다
  
  1. request_format(tag, params_map)    -> client side
    1. wireprotocol에서 공통으로 사용하는 OrderedMap 생성
    2. request_map 설정
        1. tag : hostname/module명.함수명
        2. params_map: 실제 rpc 함수에 전달될 parameter map
    3. encoding -> pickle.dumps()이용
    4. send

  2. request_parse      -> server side
    1. decoding -> pickle.loads() 사용
    
  3. request process    -> server side
  
  4. response_format(cmd, succ, response)  -> server side
     
     ex)   
        resp_map = OrderedMap()
        resp_map['command'] = cmd
        resp_map['succ']    = succ
        resp_map['response']= response
        
        return self.data_encoding(resp_map)
        
    1. wireprotocol에서 공통으로 사용하는 OrderedMap 생성
    2. response_map 설정
        1. command : 클라이언트에서 요청한 명령어        
        2. succ    : 명령 성공/실패 여부
        3. response: 응답메시지(실패시 에러메시지)        
    3. encoding -> pickle.dumps()이용
    4. send
    
  5. response_parse(params_map)  -> client side
     
     ex)   
        self.data_decoding(map)                
        cmd     = map['command']
        succ    = map['succ']
        response= map['response']        
        if succ == True:
            return (succ, response)
        else:
            errmsg = "%s Error :: \n[%s]" % (cmd, response)
            log.error(errmsg)
            return (succ, response)
        
    1. decoding -> pickle.loads() 사용
    2. params_map parse
        1. command : 클라이언트에서 요청한 명령어        
        2. succ    : 명령 성공/실패 여부
        3. response: 응답메시지(실패시 에러메시지)        
    3. succ -> False 이면 에러메시지 출력
    4. (succ, response) 튜플 리턴

  6. if succ response 처리, else ???(재시도 해야하나??)
   
"""

# Passes Python2.7's test suite and incorporates all the latest updates.
# Copyright (C) Raymond Hettinger, MIT license

try:
    from thread import get_ident as _get_ident
except ImportError:
    from dummy_thread import get_ident as _get_ident

try:
    from _abcoll import KeysView, ValuesView, ItemsView
except ImportError:
    pass
import traceback, os, sys
import zlib
import time

class OrderedMap(dict):
    'Dictionary that remembers insertion order'
    # An inherited dict maps keys to values.
    # The inherited dict provides __getitem__, __len__, __contains__, and get.
    # The remaining methods are order-aware.
    # Big-O running times for all methods are the same as for regular dictionaries.

    # The internal self.__map dictionary maps keys to links in a doubly linked list.
    # The circular doubly linked list starts and ends with a sentinel element.
    # The sentinel element never gets deleted (this simplifies the algorithm).
    # Each link is stored as a list of length three:  [PREV, NEXT, KEY].

    def __init__(self, *args, **kwds):
        '''Initialize an ordered dictionary.  Signature is the same as for
        regular dictionaries, but keyword arguments are not recommended
        because their insertion order is arbitrary.

        '''
        if len(args) > 1:
            raise TypeError('expected at most 1 arguments, got %d' % len(args))
        try:
            self.__root
        except AttributeError:
            self.__root = root = []  # sentinel node
            root[:] = [root, root, None]
            self.__map = {}
        self.__update(*args, **kwds)

    def __setitem__(self, key, value, dict_setitem=dict.__setitem__):
        'od.__setitem__(i, y) <==> od[i]=y'
        # Setting a new item creates a new link which goes at the end of the linked
        # list, and the inherited dictionary is updated with the new key/value pair.
        if key not in self:
            root = self.__root
            last = root[0]
            last[1] = root[0] = self.__map[key] = [last, root, key]
        dict_setitem(self, key, value)

    def __delitem__(self, key, dict_delitem=dict.__delitem__):
        'od.__delitem__(y) <==> del od[y]'
        # Deleting an existing item uses self.__map to find the link which is
        # then removed by updating the links in the predecessor and successor nodes.
        dict_delitem(self, key)
        link_prev, link_next, key = self.__map.pop(key)
        link_prev[1] = link_next
        link_next[0] = link_prev

    def __iter__(self):
        'od.__iter__() <==> iter(od)'
        root = self.__root
        curr = root[1]
        while curr is not root:
            yield curr[2]
            curr = curr[1]

    def __reversed__(self):
        'od.__reversed__() <==> reversed(od)'
        root = self.__root
        curr = root[0]
        while curr is not root:
            yield curr[2]
            curr = curr[0]

    def clear(self):
        'od.clear() -> None.  Remove all items from od.'
        try:
            for node in self.__map.itervalues():
                del node[:]
            root = self.__root
            root[:] = [root, root, None]
            self.__map.clear()
        except AttributeError:
            pass
        dict.clear(self)

    def popitem(self, last=True):
        """od.popitem() -> (k, v), return and remove a (key, value) pair.
        Pairs are returned in LIFO order if last is true or FIFO order if false.

        """
        if not self:
            raise KeyError('dictionary is empty')
        root = self.__root
        if last:
            link = root[0]
            link_prev = link[0]
            link_prev[1] = root
            root[0] = link_prev
        else:
            link = root[1]
            link_next = link[1]
            root[1] = link_next
            link_next[0] = root
        key = link[2]
        del self.__map[key]
        value = dict.pop(self, key)
        return key, value

    # -- the following methods do not depend on the internal structure --

    def keys(self):
        """'od.keys() -> list of keys in od"""
        return list(self)

    def values(self):
        """od.values() -> list of values in od"""
        return [self[key] for key in self]

    def items(self):
        """od.items() -> list of (key, value) pairs in od"""
        return [(key, self[key]) for key in self]

    def iterkeys(self):
        """od.iterkeys() -> an iterator over the keys in od"""
        return iter(self)

    def itervalues(self):
        """od.itervalues -> an iterator over the values in od"""
        for k in self:
            yield self[k]

    def iteritems(self):
        """od.iteritems -> an iterator over the (key, value) items in od"""
        for k in self:
            yield (k, self[k])

    def update(*args, **kwds):
        """od.update(E, **F) -> None.  Update od from dict/iterable E and F.

        If E is a dict instance, does:           for k in E: od[k] = E[k]
        If E has a .keys() method, does:         for k in E.keys(): od[k] = E[k]
        Or if E is an iterable of items, does:   for k, v in E: od[k] = v
        In either case, this is followed by:     for k, v in F.items(): od[k] = v

        """
        if len(args) > 2:
            raise TypeError('update() takes at most 2 positional '
                            'arguments (%d given)' % (len(args),))
        elif not args:
            raise TypeError('update() takes at least 1 argument (0 given)')
        self = args[0]
        # Make progressively weaker assumptions about "other"
        other = ()
        if len(args) == 2:
            other = args[1]
        if isinstance(other, dict):
            for key in other:
                self[key] = other[key]
        elif hasattr(other, 'keys'):
            for key in other.keys():
                self[key] = other[key]
        else:
            for key, value in other:
                self[key] = value
        for key, value in kwds.items():
            self[key] = value

    __update = update  # let subclasses override update without breaking __init__

    __marker = object()

    def pop(self, key, default=__marker):
        """od.pop(k[,d]) -> v, remove specified key and return the corresponding value.
        If key is not found, d is returned if given, otherwise KeyError is raised.

        """
        if key in self:
            result = self[key]
            del self[key]
            return result
        if default is self.__marker:
            raise KeyError(key)
        return default

    def setdefault(self, key, default=None):
        'od.setdefault(k[,d]) -> od.get(k,d), also set od[k]=d if k not in od'
        if key in self:
            return self[key]
        self[key] = default
        return default

    def __repr__(self, _repr_running={}):
        'od.__repr__() <==> repr(od)'
        call_key = id(self), _get_ident()
        if call_key in _repr_running:
            return '...'
        _repr_running[call_key] = 1
        try:
            if not self:
                return '%s()' % (self.__class__.__name__,)
            return '%s(%r)' % (self.__class__.__name__, self.items())
        finally:
            del _repr_running[call_key]

    def __reduce__(self):
        'Return state information for pickling'
        items = [[k, self[k]] for k in self]
        inst_dict = vars(self).copy()
        for k in vars(OrderedMap()):
            inst_dict.pop(k, None)
        if inst_dict:
            return (self.__class__, (items,), inst_dict)
        return self.__class__, (items,)

    def copy(self):
        'od.copy() -> a shallow copy of od'
        return self.__class__(self)

    @classmethod
    def fromkeys(cls, iterable, value=None):
        '''OD.fromkeys(S[, v]) -> New ordered dictionary with keys from S
        and values equal to v (which defaults to None).

        '''
        d = cls()
        for key in iterable:
            d[key] = value
        return d

    def __eq__(self, other):
        '''od.__eq__(y) <==> od==y.  Comparison to another OD is order-sensitive
        while comparison to a regular mapping is order-insensitive.

        '''
        if isinstance(other, OrderedMap):
            return len(self) == len(other) and self.items() == other.items()
        return dict.__eq__(self, other)

    def __ne__(self, other):
        return not self == other

    # -- the following methods are only used in Python 2.7 --

    def viewkeys(self):
        "od.viewkeys() -> a set-like object providing a view on od's keys"
        return KeysView(self)

    def viewvalues(self):
        "od.viewvalues() -> an object providing a view on od's values"
        return ValuesView(self)

    def viewitems(self):
        "od.viewitems() -> a set-like object providing a view on od's items"
        return ItemsView(self)

    # 모든 자료구조를 파악하여 예쁘게 출력
    @staticmethod
    def detail_print(obj, indent=2):
        """
        모든 자료구조를 파악하여 예쁘게 출력.
        딕셔너리는 키값으로 소트하여 예쁘게 보여준다.
        """
        space = '  '
            
        if isinstance(obj, list):
            # 리스트인 경우
            print("%s %s" % (space * (indent), '['))
            
            for value in obj:
                if isinstance(value, list):
                    # print("dict inside list")
                    print("%s %-20s -> %s" % (space * (indent + 1), str(value), len(value)))
                    OrderedMap.detail_print(value, indent + 2)
                elif isinstance(value, dict):
                    # print("dict inside list")
                    OrderedMap.detail_print(value, indent + 2)
                else:
                    print("%s %s " % (space * (indent + 1), str(value)))
            
            print("%s %s" % (space * (indent), ']'))
            
        elif isinstance(obj, dict):    
            # 딕셔너리인 경우      
            print("%s %s" % (space * (indent), '{'))
              
            keylist = obj.keys()
            # keylist.sort()  
            for key in keylist:
                value = obj[key]
                if isinstance(value, list):                
                    # print("list inside dict")
                    print("%s %-20s -> %s" % (space * (indent + 1), str(key), len(value)))
                    OrderedMap.detail_print(value, indent + 2)
                elif isinstance(value, dict):
                    # print("dict inside dict")
                    print("%s %-20s -> %s" % (space * (indent + 1), str(key), len(value)))
                    OrderedMap.detail_print(value, indent + 2)
                else:                
                    print("%s %-20s -> %s" % (space * (indent + 1), str(key), str(value)))
            print("%s %s" % (space * (indent), '}'))
        else:
            # 그외 자료구조인 경우
            print("%s %s " % (space * (indent + 1), str(obj)))




import pickle

def data_encoding(obj):
    """송신할 데이터 인코딩"""
    return pickle.dumps(obj)

def data_decoding(obj):
    """수신된 데이터 디코딩"""
    
    return pickle.loads(obj)

def write_to_file_cache(map, file):
    """map 데이터를 받아서 encoding 한 뒤 파일에 저장"""    
    
    pkl_file = open(file, 'wb')
    pickle.dump(map, pkl_file)
    pkl_file.close()            

def read_from_file_cache(file):
    """파일에 인코딩되어 저장된 map 데이터를 읽어서 디코딩하여 제공"""
    pkl_file = open(file, 'rb')    
    map = pickle.load(pkl_file)
    pkl_file.close()
    
    return map

def make_tag(hostname, module):
    """request 를 요청한 클라이언트 식별자
        ex) cnode05-m.t2pod1.kr-2.epc.ucloud.com/serv_test
    """    
    return hostname + "/" + module

def request_format(tag, params_map):
    """서버에 요청할 명령어 생성(인코딩 포함)"""
    request_map = OrderedMap()
    
    request_map['tag'] = tag
    request_map['params'] = params_map

    enc_request_map = data_encoding(request_map)     
    return enc_request_map

def request_parse(enc_request_map):
    """요청된 명령어 디코딩 & 요청 명령어 분해후 후 튜틀(요청식별자, 실제 요청명령어)로 리턴"""
    
    req_map = data_decoding(enc_request_map)
    tag = req_map['tag']
    request_map = req_map['params']
    
    return (tag, request_map)

def response_format(cmd, succ, response):
    """요청된 명령어에 대한 응답 메시지 생성(인코딩 포함)"""
    
    response_map = OrderedMap()
    response_map['command'] = cmd
    response_map['succ'] = succ
    response_map['response'] = response
    
    # stick = time.time()
    enc_response_map = data_encoding(response_map)
    # print("    => response_format.data_encoding 수행시간 %s" % (time.time() - stick))
    
    return enc_response_map

def response_parse(enc_response_map):
    """응답 메시지 디코딩 & 결과 튜플(성공여부, 실제 응답)로 리턴"""
     
    response_map = data_decoding(enc_response_map)                
    cmd = response_map['command']
    succ = response_map['succ']
    
    response = response_map['response']
    
    if succ == True:
        return (succ, response)
    else:
        errmsg = "%s Error :: \n[%s]" % (cmd, response)        
        return (succ, response)    

if __name__ == '__main__':
    
    def make_orderedmap_test_1():

        #
        # OrderedMap 생성 및 활용 셈플
        
        try:
            print "# OrderedMap 생성 및 활용 셈플1"
            manager_conf_map = OrderedMap()
            meta_repository_serv_conf_map = OrderedMap()
            manager_base_module_conf_map = OrderedMap()
            
            manager_conf_map['내용'] = 'cdp urc의 매니저에서 필요한 구성정보들을 제공'
            manager_conf_map['meta_repository_serv_conf'] = meta_repository_serv_conf_map
            manager_conf_map['manager_base_module_conf'] = manager_base_module_conf_map
            
            
            meta_repository_serv_conf_map['config_serv_ip'] = '10.2.8.52'
            meta_repository_serv_conf_map['config_serv_port'] = 8501
            meta_repository_serv_conf_map['master_serv_ip'] = '10.2.8.52'
            meta_repository_serv_conf_map['master_serv_port'] = 8502
            meta_repository_serv_conf_map['monitor_serv_ip'] = '10.2.8.52'
            meta_repository_serv_conf_map['monitor_serv_port'] = 8503
            
            manager_base_module_conf_map['monitor'] = 'monitorServer'
            manager_base_module_conf_map['processor'] = 'processor.baseProcessor'
            
            OrderedMap.detail_print(manager_conf_map)
            
        except Exception, e:
            print e
            return False
        
        return True
    
    def make_orderedmap_test_2():
        #
        # OrderedMap 생성 및 활용 셈플
        
        print "# OrderedMap 생성 및 활용 셈플2"
        
        try:    
            hangle = 'cdp urc의 매니저에서 필요한 구성정보들을 제공'
            ip = "10.2.8.52"
            port = 8051
            ms_module = 'monitorServer'
            pc_module = 'processor.baseProcessor'
                
            map = OrderedMap({    
               '내용': hangle,
               'meta_repository_serv_conf':
                 {
                   'config_serv_ip'   : ip,
                   'config_serv_port' : port,
                   'master_serv_ip'   : ip,
                   'master_serv_port' : port,
                   'monitor_serv_ip'  : ip,
                   'monitor_serv_port': port
                 },
               'manager_base_module_conf':
                 {
                   'monitor'  : ms_module,
                   'processor': pc_module
                 }
             })
        
            OrderedMap.detail_print(map)
            
        except Exception, e:
            print e
            return False
         
        return True
        
    def make_orderedmap_test_3():
        #
        # OrderedMap 생성 및 활용 셈플
        
        print "# OrderedMap 생성 및 활용 셈플2"
        
        try:    
            hangle = 'cdp urc의 매니저에서 필요한 구성정보들을 제공'
            ip = "10.2.8.52"
            port = 8051
            ms_module = 'monitorServer'
            pc_module = 'processor.baseProcessor'
                
            map = OrderedMap({    
               '내용': hangle,
               'meta_repository_serv_conf':
                 {
                   'config_serv_ip'   : ip,
                   'config_serv_port' : port,
                   'master_serv_ip'   : ip,
                   'master_serv_port' : port,
                   'monitor_serv_ip'  : ip,
                   'monitor_serv_port': port
                 },
               'manager_base_module_conf':
                 {
                   'monitor'  : ms_module,
                   'processor': pc_module
                 }
             })
        
        except Exception, e:
            print e
        
        return map
        
    def local_file_caching_test(map):    
        #
        # OrderedMap을 로컬 캐슁에 사용하기 위한 셈플
        
        try:
            print "# OrderedMap을 로컬 캐슁에 사용하기 위한 셈플"
            
            # 로컬파일에 저장
            file = "./config.pkl"
            write_to_file_cache(map, file)
            
            # 로컬파일에서 읽기
            map = read_from_file_cache(file)            
            print "# read picked data from file"
            OrderedMap.detail_print(map)
        except:
            print "Error : ", traceback.format_exc()
            return False
        
        return True
    
    ##############################################################
    # 1번방식으로 하나씩 만들어 주면 Order이 보존되나
    # 2번방식으로 한꺼번에 만들어 주면 Order 보장안됨.
    ##############################################################
#    if make_orderedmap_test_1():
#        print "# SUCC:: wireprotocol.OrderedMap Method-1(onebyone) Creation"
#    else:
#        print "# FAIL:: wireprotocol.OrderedMap Method-1(onebyone) Creation"
#    
#    if make_orderedmap_test_2():
#        print "# SUCC:: wireprotocol.OrderedMap Method-2(batch) Creation Succ"
#    else:
#        print "# wireprotocol.OrderedMap Method-2(batch) Creation Fail"
    
    map = make_orderedmap_test_3()    
        
    if local_file_caching_test(map):
        print "# SUCC:: wireprotocol.OrderedMap local_file_caching_test Succ"
    else:
        print "# wireprotocol.OrderedMap local_file_caching_test Fail"
        
        
