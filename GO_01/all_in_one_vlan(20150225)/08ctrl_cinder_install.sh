#! /bin/bash

ctrl_cinder_install() {

    echo '
    # ------------------------------------------------------------------------------
    ### ctrl_cinder_install!!!
    # ------------------------------------------------------------------------------'
    
    #Install some deps
    apt-get install -y linux-headers-`uname -r` \
        build-essential \
        python-mysqldb xfsprogs
    
    #Install Cinder Things
    apt-get install -y open-iscsi \
        cinder-api \
        cinder-scheduler \
        cinder-volume  \
        python-cinderclient tgt
    
    #Restart services
    service open-iscsi restart
    
    echo '>>> check result------------------------------------------------------'
    dpkg -l | egrep "linux-headers-`uname -r`|build-essential|python-mysqldb|xfsprogs"
    dpkg -l | egrep "open-iscsi|cinder-api|cinder-scheduler|cinder-volume|python-cinderclient|tgt"    
    echo '# --------------------------------------------------------------------'

}


function ctrl_cinder_uninstall() {

    echo '
    # --------------------------------------------------------------------------
    ### ctrl_cinder_uninstall
    # --------------------------------------------------------------------------'    
    
    echo '  ##service cinder-api stop'
    service cinder-api stop
    service cinder-scheduler stop
    service cinder-volume stop
    service open-iscsi stop
    
    echo '>>> before uninstall glance ----------------------------------------'
    dpkg -l | grep cinder    
    echo '#---------------------------------------------------------------------'
    
    apt-get -y purge open-iscsi \
        cinder-api \
        cinder-scheduler \
        cinder-volume  \
        tgt
    
    echo '>>> after uninstall glance -----------------------------------------'
    dpkg -l | egrep "open-iscsi|\
        cinder-api|cinder-scheduler|cinder-volume|\
        python-cinderclient|tgt"  
    echo '#---------------------------------------------------------------------'
    
}    

ctrl_cinder_db_create() {

    echo '
    # ------------------------------------------------------------------------------
    ### ctrl_cinder_db_create!!!
    # ------------------------------------------------------------------------------'
    mysql -uroot -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE cinder;'
    mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '$MYSQL_CINDER_PASS';"
    mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '$MYSQL_CINDER_PASS';"

    echo '>>> check result------------------------------------------------------'
    mysql -u root -p${MYSQL_ROOT_PASS} -h localhost -e "show databases;"    
    echo '# --------------------------------------------------------------------'
    
}


ctrl_cinder_configure() {
    
    echo '
    # ------------------------------------------------------------------------------
    ### ctrl_cinder_configure(${CINDER_CONF}) !!!
    # ------------------------------------------------------------------------------'
    
    #Configure Cinder
    #cp ${CINDER_CONF}{,.bak}
    backup_org ${CINDER_CONF}

cat > ${CINDER_CONF} <<EOF
# ------------------------------------------------------------------------------
[DEFAULT]
rootwrap_config=${ROOTWRAP_CONF}
api_paste_config=${CINDER_API}
iscsi_helper=tgtadm
volume_name_template = volume-%s

#volume_group = cinder-volumes
# LJG: 디스크하나를 통짜로 LVM 설정한 경우 루트 디렉토리도 포함되어 있으므로 
#      단순하게 lvm vgrename 으로 이름을 바꾸면 안된다. 
#      리부팅할 때 루트볼륨을 못찾아 부팅조차 안된다.
#      나중에 여러개 하드디스크 붙이고 거기에 volume group 이름 지을때만 cinder-volumes라 명하고
#      지금은 cinder.config에서 수정해 주자. 
volume_group = controller-vg
verbose = True
use_syslog = True
syslog_log_facility = LOG_LOCAL0

auth_strategy = keystone

rabbit_host = ${CTRL_HOST}
rabbit_port = 5672
state_path = /var/lib/cinder/

[database]
backend=sqlalchemy
connection = mysql://cinder:${MYSQL_CINDER_PASS}@${CTRL_HOST}/cinder

[keystone_authtoken]
service_protocol = http
service_host = ${CTRL_HOST}
service_port = 5000
auth_host = ${CTRL_HOST}
auth_port = 35357
auth_protocol = http
auth_uri = http://${CTRL_HOST}:5000/
admin_tenant_name = ${SERVICE_TENANT}
admin_user = ${CINDER_SERVICE_USER}
admin_password = ${CINDER_SERVICE_PASS}
# ------------------------------------------------------------------------------
EOF
    echo '>>> check result
    # ------------------------------------------------------------------------------'
    cat $CINDER_CONF
    echo '
    # ------------------------------------------------------------------------------'
}


ctrl_cinder_restart() {
    
    echo '
    # ------------------------------------------------------------------------------
    ### ctrl_cinder_restart() !!!
    # ------------------------------------------------------------------------------'
    
    echo '  cinder DB 동기화'    
    cinder-manage db sync
    
    # echo '  cinder 를 위한 LVM 생성'    
    # case1) ubuntu 설치시에 lvm을 설치한 경우
    # LJG: vgdisplay를 이용하여 vg 이름을 파악하고 cinder에서 사용하는 name(cinder-volumes)로 변경
    #      이 부분은 snode를 다로 구축할 때 진지하게 생각해야 할 부분.
    # lvm vgrename controller-vg cinder-volumes
    
    #case2) 신규 하드에 lvm을 설치해야 하는 경우
    #fdisk /dev/sda
    #(and hit: n p 1 ENTER ENTER t 8e w)
    #pvcreate /dev/sda3
    #vgcreate cinder-volumes /dev/sda3
    
    # LJG: iscsi를 위해 loopback 파일시스템을 만든다.
    echo "iscsi를 위해 loopback 파일시스템을 만든다."
    echo "dd if"
    #dd if=/dev/zero of=cinder-volumes bs=1 count=0 seek=1G
    echo "losetup /dev/loop2 cinder-volumes"
    #losetup /dev/loop2 cinder-volumes
    echo "pvcreate"
    #pvcreate /dev/loop2
    echo "vgcreate"
    # LJG : 에러발생 -> Incorrect metadata area header checksum on /dev/loop2 at offset 4096
    #vgcreate cinder-volumes /dev/loop2

    #Restart services
    for process in $( ls /etc/init/cinder-* | cut -d'/' -f4 | cut -d'.' -f1) ; do service $process restart; done
    
    echo '>>> check result -----------------------------------------------------'
    ps -ef | grep cinder
    echo '# --------------------------------------------------------------------'
    
}