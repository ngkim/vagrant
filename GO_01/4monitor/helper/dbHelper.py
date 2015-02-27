#!/usr/bin/env python
# -*- coding: utf-8 -*-

#===========================================================================
# tcl remote-sql-net porting to python/jython
#
#       Network Version of isqltcl
#       Created by JinGoo Lee 1997/12/10
#
#       Last Update : 2013/09/10
#
#       Cloud Service Development Team, Korea Telecom
#===========================================================================
"""
LJG: 모든 데이터베이스는 variable binding을 사용할 때 가장 안전적으로 동작.
따라서 이를 지원하기 위해 query문을 myqsl 홈페이지에서 제안한 것처럼
query 튜플과 variable 튜플로 나누어서 질의에 사용한다.(한 3일 고생했슴)
항상 이런게 해놓으면 단순하지만 찾기는 어렵고 경험이 필요한 부분.
처음에는 그냥 쓰는데 나중에 문제가 생기는 부분들임.
그러나, jython은 variable binding과 한글처리 2개 다 안됨. ㅜㅜ
"""
import sys
import traceback
import platform

rsql_runenv = "python"

jdbc_driver = '/var/log/cdp_master/helper/mysql-jdbc-5.1.26.jar'

if platform.system() == "Java":
    rsql_runenv = "jython"
    
    from com.ziclix.python.sql import zxJDBC    
    def importJar(jarFile):
        '''
        import a jar at runtime (needed for JDBC [Class.forName])
    
        adapted from http://forum.java.sun.com/thread.jspa?threadID=300557
        Author: SG Langer Jan 2007 translated the above Java to Jython
        Author: seansummers@gmail.com simplified and updated for jython-2.5.3b3
    
        >>> importJar('jars/jtds-1.2.5.jar')
        >>> import java.lang.Class
        >>> java.lang.Class.forName('net.sourceforge.jtds.jdbc.Driver')
        <type 'net.sourceforge.jtds.jdbc.Driver'>
        '''
        from java.net  import URL, URLClassLoader
        from java.lang import ClassLoader
        from java.io   import File
        
        print "## Inside importJar <%s>" % jarFile
        
        m = URLClassLoader.getDeclaredMethod("addURL", [URL])
        m.accessible = 1
        m.invoke(ClassLoader.getSystemClassLoader(), [File(jarFile).toURL()])
    
    # LJG: jython dynamic loader에 문제가 있어 찾은 해결책(반나절 고생..) 
    
    importJar(jdbc_driver)
#    import java.lang.Class
#    java.lang.Class.forName('com.mysql.jdbc.Driver')
else:
    import MySQLdb
    import MySQLdb.cursors

class myRSQL():
 
    def __init__(self):
        global rsql_mode
        self.auto_commit = True    
        self.dbinfo = {}  # db info 
        self.dbhand = {}  # db handle
        self.dbcurs = {}  # db dbcurs
        self.dbstat = {}  # db connection status('CONN', 'DISCONN')
        self.runenv = rsql_runenv
        self.timeout = 3   

    def connect(self, name, host, id, pw, db, port=3306):        
        if not self.dbinfo.has_key(name):
            """최초 접속 요청인 경우"""
            
            # print "[%s] db register" % name
            
            # 접속 요청 정보 등록
            self.dbinfo[name] = [host, id, pw, db, port]
            self.dbstat[name] = 'DISCONN'        

        if self.dbstat[name] == 'CONN' :
            return
        
        # DB 접속
        connstr = ""        
        try:
            if self.runenv == "python":
                
                connstr = "(host=%s, port=%d, user=%s, passwd=%s, db=%s)" % (host, port, id, pw, db)                
                conn = MySQLdb.connect(host=host, port=port,
                                 user=id, passwd=pw,
                                 db=db, connect_timeout=self.timeout)
                # cursorclass = MySQLdb.cursors.SSCursor -> 대용량 데이터 로딩시 필수
            elif self.runenv == "jython":
                            
                # d, u, p, v = "jdbc:mysql://14.63.161.143/cdp", 'root', 'cloud1004', 'com.mysql.jdbc.Driver'                                    
                url = 'jdbc:mysql://%s/%s' % (host, db)
                driver = 'com.mysql.jdbc.Driver'
                connstr = "(url=%s, id=%s, pw=%s, driver=%s)" % (url, id, pw, driver)
                conn = zxJDBC.connect(url, id, pw, driver, CHARSET='utf-8')
        except:
            errmsg = "\n# DB Helper Connect Error:: Constr[%s] => \n[%s]\n" % (connstr, traceback.format_exc())
            raise RuntimeError(errmsg)
        
        self.dbstat[name] = 'CONN'
        self.dbhand[name] = conn
        self.dbcurs[name] = conn.cursor()
        # encoding setting
        self.dbcurs[name].execute("SET names UTF8")
        # self.dbcurs[name].execute("SET names UTF8")
        
        print "[%s] db connect" % name
    
    def conn_check(self, name):
        if not self.dbinfo.has_key(name):
            raise RuntimeError("RSQL: Invalid DB Connection Name : %s" % name)
        
        if not self.dbstat[name] == 'CONN':
            print "[%s] db reconnect try" % name
        
            host, id, pw, db, port = self.dbinfo[name]
            self.connect(name, host, id, pw, db, port)
        
    def finish(self, name):
        """ name 관련 자료구조를 정리하고 DB 접속을 끊는다"""
        
        print "[%s] db finish(delete info & disconn dictionary)" % name
         
        if not self.dbinfo.has_key(name):
            raise RuntimeError("RSQL: Invalid DB Connection Name : %s" % name)
        
        self.disconn(name)
        
        del self.dbinfo[name]
        del self.dbhand[name]
        del self.dbcurs[name]        
        del self.dbstat[name] 
        
    def disconn(self, name):
        """name 관련  데이터베이스 접속을 끊는다. """
        #print "[%s] db disconn" % name
        
        if not self.dbhand.has_key(name):            
            raise "RSQL: Invalid DB Connection Name : %s" % name
    
        if self.dbstat.has_key(name) and self.dbstat[name] == 'CONN':            
            self.dbcurs[name].close()
            self.dbhand[name].close()
            self.dbstat[name] = 'DISCONN' 
                  
            #print "[%s] db disconn succ!!!" % name
   
    def bigdata(self, name, num, query, args=None):
        """ 
        bigdata 질의 전용
                테이블 레코드가 10만개이상을 bigdata라 가정하면,
                사용자가 select all을 하는 순간 mysql clinet는 모든 레코드를 가져와서 처리하는 구조이기때문에
                프로그램이 hang 걸린다. 이를 해결하기 위해서는
                접속할때 Server Side dbcurs를 이용하여 클라이언트에서 하나씩 가져와 처리하는 구조를 사용하자
                물론 가능하면 chunk단위로 읽을수 있으면 효율적일 것이다.        
        """
        
        if self.dbinfo.has_key(name):
            self.disconn(name)
         
        # DB 접속
        
        connstr = ""
        host, id, pw, db, port = self.dbinfo[name]
        
        try:
            if self.runenv == "python":
                
                connstr = "(host=%s, port=%d, user=%s, passwd=%s, db=%s)" % (host, port, id, pw, db)
                conn = MySQLdb.connect(host=host, port=port,
                                     user=id, passwd=pw,
                                     db=db,
                                     cursorclass=MySQLdb.cursors.SSCursor)
                
            elif self.runenv == "jython":
                            
                # d, u, p, v = "jdbc:mysql://14.63.161.143/cdp", 'root', 'cloud1004', 'org.gjt.mm.mysql.Driver'                                    
                url = 'jdbc:mysql://%s/%s' % (host, db)
                driver = 'com.mysql.jdbc.Driver'
                connstr = "(url=%s, id=%s, pw=%s, driver=%s)" % (url, id, pw, driver)
                conn = zxJDBC.connect(url, id, pw, driver)
                
        except Exception, e:
            errmsg = "\n# DB Helper BigData Connect Error:: Constr[%s] => \n[%s]\n" % (connstr, traceback.format_exc())
            raise RuntimeError(errmsg)
     
     
        print "[%s] db connect for bigdata succ !!" % name
        
        self.dbhand[name] = conn
        self.dbcurs[name] = conn.cursor();
        # encoding setting
        self.dbcurs[name].execute("SET names UTF8")        
        
        cursor = self.dbcurs[name]
        cursor.execute(query, args)
        fetch = cursor.fetchmany
        while True:
            if not rows: break
            yield rows
            # for row in rows:
            #     yield row    
        
        # 다음 질의부터는 일반적인 client side dbcurs 사용하도록 접속 끊는다.
        self.disconn(name)
    
    def do_query(self, name, query, args=None):
        
        self.conn_check(name)
        dbcurs = self.dbcurs[name]
        dbcurs.execute(query, args)
        
        return dbcurs
    
    def all(self, name, query, args=None):
        
        try:
            dbcurs = self.do_query(name, query, args)
        except:            
            errmsg = "\n# DB Helper query Error:: 질의[%s %s] => \n[%s]\n" % (query, args, traceback.format_exc())
            raise RuntimeError(errmsg)
        
        return dbcurs.fetchall()

        
    def all_detail(self, name, query, args=None):
        self.conn_check(name)
        dbcurs = self.dbcurs[name]
        dbcurs.execute(query, args)
        
        print "---------------------------------------"
        if args:
            print "query => \n[%s]" % (query % args)
        else:
            print "query => \n[%s]" % (query)
        print "---------------------------------------"
        print "recs num :: [%d]" % dbcurs.rowcount
        print "---------------------------------------"
        print "fields   :: ", self.colheader(name)   
        print "---------------------------------------"
        print "descs    :: ", dbcurs.description;
        print "---------------------------------------"
        
        import pprint 
        pprint.pprint(dbcurs.description)
        
        """
        ---------------------------------------
        cursor description -> C:\Python27\Lib\site-packages\MySQLdb\constants\FIELD_TYPE.py
        ---------------------------------------
        DESCRIPTION_NAME
        DESCRIPTION_TYPE_CODE
        DESCRIPTION_DISPLAY_SIZE
        DESCRIPTION_INTERNAL_SIZE
        DESCRIPTION_PRECISION
        DESCRIPTION_SCALE
        DESCRIPTION_NULL_OK
        ---------------------------------------
        MySQLdb.constants.FIELD_TYPE -> DESCRIPTION_TYPE_CODE
        DECIMAL     = 0
        TINY        = 1
        SHORT       = 2
        LONG        = 3
        FLOAT       = 4
        DOUBLE      = 5
        NULL        = 6
        TIMESTAMP   = 7
        LONGLONG    = 8
        INT24       = 9
        DATE        = 10
        TIME        = 11
        DATETIME    = 12
        YEAR        = 13
        NEWDATE     = 14
        VARCHAR     = 15
        BIT         = 16
        NEWDECIMAL  = 246
        ENUM        = 247
        SET         = 248
        TINY_BLOB   = 249
        MEDIUM_BLOB = 250
        LONG_BLOB   = 251
        BLOB        = 252
        VAR_STRING  = 253
        STRING      = 254
        GEOMETRY    = 255
        
        CHAR = TINY
        INTERVAL = ENUM    
        ---------------------------------------            
        ex)
        (
        ('vm_id',             8,  6,  20,  20, 0, 0), 
        ('vm_name',         253, 48, 765, 765, 0, 0), 
        ('vm_instance_name',253, 77, 765, 765, 0, 0), 
        ('vm_state',        253,  9,  96,  96, 0, 0),
        ---------------------------------------
        """  
        cnt = 0
        result = dbcurs.fetchall()
        for rec in result:
            cnt += 1
            # print "  %d => %s" % (cnt, rec)   
        print "---------------------------------------" 


    def num(self, name, num, query, args=None):
        
        try:
            dbcurs = self.do_query(name, query, args)
        except:            
            errmsg = "\n# DB Helper query Error:: 질의[%s %s] => \n[%s]\n" % (query, args, traceback.format_exc())
            raise RuntimeError(errmsg)
                
        return dbcurs.fetchmany(num)
                  
    def one(self, name, query, args=None):
        try:
            dbcurs = self.do_query(name, query, args)
        except:            
            errmsg = "\n# DB Helper query Error:: 질의[%s %s] => \n[%s]\n" % (query, args, traceback.format_exc())
            raise RuntimeError(errmsg)
        return dbcurs.fetchone()
    
    def run(self, name, query, args=None):
        
        self.conn_check(name)
        db = self.dbhand[name]
        dbcurs = self.dbcurs[name]
        
#         try:
#             # Execute the SQL command            
#             r = dbcurs.execute(query, args)            
#             # Commit your changes in the database
#             if self.auto_commit: db.commit()            
#         except Exception, e:            
#             # Rollback in case there is any error
#             if self.auto_commit: db.rollback()
#             errmsg = "\n# DB Helper run Error:: 질의[%s %s] => \n[%s]\n" % (query, args, traceback.format_exc())
#             raise RuntimeError(errmsg)
        try:
            # Execute the SQL command            
            dbcurs.execute(query, args)            
            # Commit your changes in the database
            if self.auto_commit: db.commit()            
        except (AttributeError, MySQLdb.OperationalError):            
            # Rollback in case there is any error
            # if self.auto_commit: db.rollback()
            (host, id, pw, db, port) = self.dbinfo[name]
            self.connect(name, host, id, pw, db, port)
            dbcurs.execute(query, args)            
            # Commit your changes in the database
            if self.auto_commit: db.commit()
        
    def getfields(self, name):
        dbcurs = self.dbcurs[name]
        fields = ""
        for desc in dbcurs.description:
            colname = desc[0]
            fields += colname + ','        
        return fields.strip(',')
               
    def colheader(self, name):
        dbcurs = self.dbcurs[name]
        fmt1 = ""
        fmt2 = ""
        ch = ""
        for desc in dbcurs.description:
            # print "  => %s" % str(desc)
            colname = desc[0]
            collen = desc[2]
            
            fmt1 = '%' + str(collen) + 's,'
            fmt2 += fmt1 % colname
            
            # 컬럼 길이에 맞추면 오히려 더 보기 불편
            ch += colname + ', '
            
        return ch

    def colnames(self, name):
        dbcurs = self.dbcurs[name]
        colnames = []
        for desc in dbcurs.description:
            # print "  => %s" % str(desc)
            colname = desc[0]
            colnames.append(colname)
            
        return colnames
    
    escape_dict = {'\a':r'\a',
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
               '\9':r'\9'}
          
    def str2raw(self, text):
        """Returns a raw string representation of text
        
        LJG :: escape문자가 있는 스트링은 rawstring으로 변환해야만 insert 성공됨
        ex) 'result' -> \'result\'
        문자를 하나하나 읽어서 처리하므로 속도를 상당히 떨어뜨릴수 있다.
        따라서 escape 문자가 없는 스트링에는 적용하지 않도록 한다.
        피치 못해 많이 사용해야 하는 경우에는 c-extension plugin을 사용해야 함.
        """
        
        new_string = ''
        for char in text:
            try: new_string += self.escape_dict[char]
            except KeyError: new_string += char
        return new_string
    
    
def test():
    print "#"*80
    print "파이썬/자이썬으로 작성한 데이터베이스 라이브러리"
    if platform.system() == "Java":
        print "# jython myRSQL() test"
    else:
        print "# python myRSQL() test"
    print "#"*80    
        
    dh = myRSQL()
    
    host = '14.63.161.143'
    id = 'root'
    pw = 'cloud1004'
    
    host = '14.63.160.99'
    id = 'polinus7'
    pw = 'manager'
    
    db = 'cdp'
        
    tag = 'tf_db'
    
    # conect
    dh.connect(tag, host, id, pw, db)
    
    q = "select * from cloudstack_inventory limit 3"
        
    # sql_one test
    rec = dh.one(tag, q)
    print "-"*80
    print "# sql_one: ", rec
    dh.disconn(tag)
    
    # sql_num test    
    recs = dh.num(tag, 2, q)
    print "-"*80
    print "# sql_num 2: ", recs
    dh.disconn(tag)
    
    # sql_all test
    recs = dh.all(tag, q)
    print "-"*80
    print "# sql_all : ", recs
    dh.disconn(tag)    
        
    print "-"*80
    print "# sql_detail : "
    dh.all_detail(tag, q)
        
    # bigdata test (중요기능)        
    
    # 동일계정인 경우
    # dh.connect("netapp1", "172.27.205.154","netapp1","netapp1","TPCC", 3306)
    # 다른 계정인 경우
    dh.connect(tag, host, id, pw, db)
    print "-"*80
    print "# sql_allbynum : "   
    loop = 0
    for recs in dh.bigdata(tag, 2, "select * from cloudstack_inventory limit 7"):
        loop += 1
        print "\n##### chunk [%2d]\n" % (loop)
        for rec in recs:
            print rec      
    
    dh.run(tag, "SET names UTF8")
    
    q = "show variables like 'char%'"
    print "-"*80
    print "# sql_detail : "
    dh.all_detail(tag, q)    
    
    q = "Drop Table IF Exists test_sample" 
    print "-"*80
    print "# sql_drop_table : %s" % (q)
    dh.run(tag, q)    
    
    q = """    
    CREATE TABLE test_sample (
        id     bigint(20) NOT NULL AUTO_INCREMENT,
        raw_string varchar(100),
        PRIMARY KEY (id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8    
    """ 
    print "-"*80
    print "# sql_create_table : %s" % (q)
    dh.run(tag, q)
    
    print dh.all(tag, 'select * from test_sample')
    
    rec = '### db i/u/d test'
    q = "INSERT INTO test_sample VALUES (%s, '%s')" % (0, rec)
    print "-"*80
    print "# sql_insert : %s" % (q)    
    dh.run(tag, q)
    
    q = ("INSERT INTO test_sample VALUES (%s, %s)")
    v = (0, rec)
    print "-"*80
    print "# sql_insert : %s" % (q % v)
    dh.run(tag, q, v)

    rec = """이진구가 만든 \'myrsql\' 라이브러리"""
    rec = dh.str2raw(rec)
    q = ("INSERT INTO test_sample VALUES (%s, %s)")
    v = (0, rec)
    print "-"*80
    print "# sql_insert : %s" % (q % v)
    dh.run(tag, q, v)
                
#    dbcurs = dh.dbcurs[tag]
#    dbcurs.execute("""INSERT INTO test_sample VALUES (0, %s)""", (rec))
    
    # sql_all test
    recs = dh.all(tag, 'select * from test_sample')
    print "-"*80
    print "# sql_all : ", recs
    dh.disconn(tag)        
            
    
        
#    
#    q = "UPDATE test_sample SET raw_string = 'update_test' WHERE id = 1"
#    print "-"*80
#    print "# sql_update : %s" % (q)
#    dh.run(tag, q)
#    
#    q = "DELETE from test_sample"
#    print "-"*80
#    print "# sql_delete : %s" % (q)
#    dh.run(tag, q)


def jdbc_test():
    """LJG: zxJDBC를 사용하면 한글처리가 에러나는데 JDBC를 직접 사용하면 한글처리가 성공한다
    추후 시간을 갖고 한글관련 문제를 처리하자.오늘은 여기까지 새벽 3시다.. 정말 한글이 싫다.ㅋㅋ
    """
    import sys
    import java
    from java.lang import Class
    from java.sql import DriverManager, SQLException
    
    jdbc_user = "root"
    jdbc_password = "cloud1004"
    jdbc_url = "jdbc:mysql://14.63.161.143/cdp"
    
    DriverManager.registerDriver(Class.forName("com.mysql.jdbc.Driver").newInstance())
    
    connection = DriverManager.getConnection(jdbc_url, jdbc_user, jdbc_password)
    
    statement = connection.createStatement()
    
    sql = "select * from test_sample"
    
    rs = statement.executeQuery(sql)
    
    while rs.next():
      row = rs.getString(2)
      print row
      # print "%s -> %s" % (rs.getString("id"), id.getString("raw_string") )

def rec2map(colnames, rec):
    import collections
     
    # rec_map = {}
    rec_map = collections.OrderedDict()
    
    for i in range(len(colnames)):
        rec_map[colnames[i]] = rec[i]
    
    return rec_map



"""
set iq1   "INSERT INTO $table VALUES "               
        set iq2   "("        
        set iq3   {}
        set comma {}

        foreach fld $fields {                      
            set fld [string trim $fld]
              
            append iq2 "$comma ?"
            set comma ","

            append iq3 " \$$fld"              
            
        }

        append iq2 ")"    
        
        set query " \"$iq1 $iq2 \" $iq3"  
"""
def make_insert_query(table, colnames, rec):
    iq1 = "INSERT INTO %s VALUES " % (table)
    iq2 = "("        
    iq3 = ''    
    comma = ''

    for col in colnames:
          
        iq2 += "%s ?" % (comma)
#        set comma ","
#
#        append iq3 " \$$fld"
#
#    append iq2 ")"    
#    
#    set query " \"$iq1 $iq2 \" $iq3"
    
    
    
    
          
def auto_query():    
            
    
    db_connstr = "10.5.0.70,3306,root,n2tgdIDvdrWZTU9oIerD,cloud"
    
    (ip, port, id, pw, db) = db_connstr.split(',') 
    
    cs_db = myRSQL()
    cs_db.connect("cs_inv", ip, id, pw, db, int(port))       

    query = """
    SELECT 
        vm.id                     AS vm_id, 
        vm.name                 AS vm_name,
        vm.instance_name         AS vm_instance_name,
        vm.state                 AS vm_state, 
        
        so.cpu                    AS vm_cpu,
        so.ram_size              AS vm_ram,
        
        -- vm's nic info    
        (SELECT 
            -- concat(nic.instance_id,'-',COUNT(*))
            COUNT(*)
         FROM         
            cloud.nics AS nic
         WHERE
            nic.removed IS NULL AND        
            vm.id = nic.instance_id     
        ) AS vm_nic_count,
        
        -- vm's volume info    
        (SELECT     
            -- concat(count(*), '-', sum(vol.size)) 
            count(*)
         FROM         
            cloud.volumes AS vol
         WHERE
            vol.removed IS NULL AND        
            vm.id = vol.instance_id
        ) AS vm_vol_count,
        
        -- vm's volume size    
        (SELECT     
            sum(vol.size)
         FROM         
            cloud.volumes AS vol
         WHERE
            vol.removed IS NULL AND        
            vm.id = vol.instance_id
        ) AS vm_vol_size_G,
        
        vm.vm_template_id         as vm_template_id,
        vm_t.name                AS vm_template_name,    
        vm_t.format                AS vm_template_format,    
        vm_t.url                AS vm_template_url,        
        
        vm.guest_os_id             as vm_guest_os_id,
        os.name                    AS vm_guest_os_name,
        
        vm.private_ip_address     AS vm_private_ip,
        
        vm.data_center_id         AS vm_zone_id,
        dc.name                    AS vm_zone_name,
        
        vm.pod_id                 AS vm_pod_id,
        pod.name                AS vm_pod_name,
        
        -- get cluster info with inline view 
        (SELECT 
            cl.name
         FROM 
            cloud.cluster AS cl,
            cloud.host AS ht
         WHERE 
            vm.host_id = ht.id AND
            ht.cluster_id = cl.id) AS vm_cluster_name,
        
        -- vm's host
        vm.host_id                 AS vm_host_id,
        ht.name                    AS vm_host_name,
        ht.status                AS vm_host_status,
        ht.type                    AS vm_host_type,
        ht.private_ip_address    AS host_private_ip,
        ht.public_ip_address    AS host_public_ip,
        ht.storage_ip_address    AS host_storage_ip,
        ht.storage_ip_address_2    AS host_storage_ip2,
        ht.cpus                    AS host_cpus,
        ht.speed                AS host_speed,
        ht.hypervisor_type        AS host_hv_type,
        ht.ram                    AS host_ram,
        ht.resource                AS host_resource,
        ht.version                AS host_version,
        ht.capabilities            AS host_capa,
        ht.dom0_memory            AS vm_host_dom0_memory,
        ht.mgmt_server_id          AS vm_host_mgmt_serv_id,
                
        vm.proxy_id             AS vm_proxy_id,
        proxy.public_ip_address    AS vm_proxy_public_ip,
        proxy.active_session    AS vm_active_session,
        -- proxy.session_details    AS vm_proxy_session_detail,
        
        vm.ha_enabled             AS vm_ha,
        vm.created                 AS vm_created,    
        vm.service_offering_id     AS vm_so_id,
    
        
        so.speed                 AS vm_speed,
        
        so.nw_rate                AS vm_nw,
        so.mc_rate                AS vm_mc,
        so.host_tag                AS vm_host_tag,
        so.limit_cpu_use        AS vm_limit_cpu_use,    
        vm.account_id             AS vm_account_id,
        ac.account_name            AS vm_account_name,
        
        vm.limit_cpu_use         AS vm_cpu_limit,
        vm.vm_type                 AS vm_type
        
    FROM 
        cloud.vm_instance         AS vm
        -- get template info
        LEFT OUTER JOIN cloud.vm_template AS vm_t
           ON vm.vm_template_id = vm_t.id
        -- get guest_os info
        LEFT OUTER JOIN cloud.guest_os AS os
           ON vm.guest_os_id = os.id
        -- get data_center info
        LEFT OUTER JOIN cloud.data_center AS dc
           ON vm.data_center_id = dc.id
        -- get pod info
        LEFT OUTER JOIN cloud.host_pod_ref AS pod
           ON vm.pod_id = pod.id
        -- get host info
        LEFT OUTER JOIN cloud.host AS ht
           ON vm.host_id = ht.id
        -- get proxy info
        LEFT OUTER JOIN cloud.console_proxy AS proxy
           ON vm.proxy_id = proxy.id
        -- get service_offering info
        LEFT OUTER JOIN cloud.service_offering AS so
           ON vm.service_offering_id = so.id
        -- get account info
        LEFT OUTER JOIN cloud.account AS ac
           ON vm.account_id = ac.id
           
    WHERE 
        vm.removed IS NULL
    LIMIT 3
    """
            
    # print query
    vm_inv_map = {}
    try:                     
        recs = cs_db.all('cs_inv', query)
        colnames = cs_db.colnames('cs_inv')
        # recs = cs_db.all_detail('cs_inv',query)return
        print colnames
        # print(query)
        print("#"* 80)
        print("get_cloudstack_inventory")
        print("recs [%s]" % len(recs))
        
#        i = 0
#        for rec in recs:
#            i += 1
#            # print("%d] %d bytes-> %s" % (i, sys.getsizeof(rec), rec))
#            rec_map = rec2map(colnames, rec)
#            print "####"
#            import pprint
#            pprint.pprint(rec_map)
#            
#        byte_size = sys.getsizeof(vm_inv_map)
#        print("get_cloudstack_inventory finish.... size[%s] bytes") % (byte_size)
        
    except Exception, e:
        errmsg = "Error :: Q[%s] => %s" % (query, e)
        print(errmsg)
    
    cs_db.disconn('cs_inv')

def cursor_parse():
    # print dir(MySQLdb.constants.FIELD_TYPE)
    _list = dir(MySQLdb.constants.FIELD_TYPE)
    for const in _list:
        _type = "MySQLdb.constants.FIELD_TYPE.%s" % const
        type_name = eval(_type)
        print "%10s -> %s" % (const, type_name)
    
    
if __name__ == '__main__':
    
    # jdbc_test()
    test()
    # auto_query()
    # cursor_parse()


"""
# mysql python sample

import datetime
import mysql.connector

cnx = mysql.connector.connect(user='scott', database='employees')
cursor = cnx.cursor()

query = ("SELECT first_name, last_name, hire_date FROM employees "
         "WHERE hire_date BETWEEN %s AND %s")

hire_start = datetime.date(1999, 1, 1)
hire_end = datetime.date(1999, 12, 31)

cursor.execute(query, (hire_start, hire_end))

for (first_name, last_name, hire_date) in cursor:
  print("{}, {} was hired on {:%d %b %Y}".format(
    last_name, first_name, hire_date))

cursor.close()
cnx.close()
"""    
