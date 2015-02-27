#! /bin/bash

function ctrl_keystone_install() { 
	
    echo "
    # ------------------------------------------------------------------------------
    ### ctrl_keystone_install() !!!
    # ------------------------------------------------------------------------------"

    echo "  1 keystone 관련 패키지 설치(ntp, keystone, python-keyring)"
    apt-get -y install ntp ngrep 
    apt-get -y install keystone python-keyring
    apt-get -y install python-keystoneclient        
    
    echo "  2. sqlite db(/var/lib/keystone/keystone.db) 삭제"
    if [ -f /var/lib/keystone/keystone.db ]; then
        rm /var/lib/keystone/keystone.db        
    fi 
    
    echo ">>> check result ----------------------------------------------------"
    dpkg -l | egrep "keystone|python-keyring|python-keystoneclient"    
    echo "# -------------------------------------------------------------------"        
    
}
   
function ctrl_keystone_config() {
    
    echo "
    # ------------------------------------------------------------------------------
    ### ctrl_keystone_config() !!!
    # ------------------------------------------------------------------------------"    

    echo "  1 keystone 데이터베이스 생성 및 권한 설정"
 
    mysql -uroot -p$MYSQL_ROOT_PASS -e "CREATE DATABASE keystone;"
    mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$MYSQL_KEYSTONE_PASS';"
    mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$MYSQL_KEYSTONE_PASS';"

    echo "  2 keystone.conf 설정(connection, admin_token, log_dir)"
	backup_org ${KEYSTONE_CONF}
	     
    sed -i "s#^connection.*#connection = mysql://keystone:${MYSQL_KEYSTONE_PASS}@${MYSQL_HOST}/keystone#" ${KEYSTONE_CONF}
    sed -i "s/^#admin_token.*/admin_token = ${SERVICE_TOKEN}/" ${KEYSTONE_CONF}
    sed -i "s,^#log_dir.*,log_dir = /var/log/keystone," ${KEYSTONE_CONF}
    
    echo "  3 keystone syslog 설정"
    echo "use_syslog = True" >> ${KEYSTONE_CONF}
    echo "syslog_log_facility = LOG_LOCAL0" >> ${KEYSTONE_CONF}    
    
    echo "  4 keystone db_sync(create all of the tables and configure them)"
    # LJG: db_sync가 잘 되었는지 항상 확인하는 절차가 필요함.  
    keystone-manage db_sync     
    
    echo "  5 keystone 재시작" 
    restart keystone
    
    echo ">>> check result ----------------------------------------------------"
    echo "use keystone;show table status;"            
    mysql -u root -p${MYSQL_ROOT_PASS} -h localhost -e "use keystone;show table status;"
    echo "# -------------------------------------------------------------------"

}

function ctrl_keystone_uninstall() {

    echo '
    # --------------------------------------------------------------------------
    ### ctrl_keystone_uninstall
    # --------------------------------------------------------------------------'    
    
    echo '  ##service keystone stop'
    service keystone stop
    
    echo '>>> before uninstall keystone ----------------------------------------'
    dpkg -l | grep keystone    
    echo '#---------------------------------------------------------------------'
    
    echo '  ##apt-get -y purge keystone'
    apt-get -y purge keystone python-keystone python-keystoneclient 
    
    echo '>>> after uninstall keystone -----------------------------------------'
    dpkg -l | grep keystone    
    echo '#---------------------------------------------------------------------'
    
}    
    

ctrl_keystone_base_user_env_create() {

    echo "
    # ------------------------------------------------------------------------------
    ### ctrl_keystone_base_user_env_create(admin tenant, admin/demo user, admin/demo rule) !!!    
    # ------------------------------------------------------------------------------"
        
    
    #
    # admin tenant 생성
        
    admin_tenant_id=$(keystone --debug tenant-list | grep "$ADMIN_TENANT " | awk '{print $2}')
    if [ $admin_tenant_id ]
    then
        printf "%s tenant already exists so delete it !!!\n" $ADMIN_TENANT
        echo "keystone tenant-delete $ADMIN_TENANT"
        keystone tenant-delete $ADMIN_TENANT
    fi
    echo "keystone tenant-create --name $ADMIN_TENANT --description "Admin Tenant" --enabled true"
    keystone tenant-create --name $ADMIN_TENANT --description "Admin Tenant" --enabled true   

    #
    # admin 사용자 생성 및 role 할당
    
    admin_user_id=$(keystone user-list | grep "$ADMIN_USER " | awk '{print $2}')
    if [ $admin_user_id ]
    then
        printf "%s user already exists so delete it !!!\n" $ADMIN_USER        
        keystone user-delete $ADMIN_USER
    fi        
    echo "keystone user-create --name $ADMIN_USER --pass $PASSWORD --enabled true"
    keystone user-create --name $ADMIN_USER --pass $PASSWORD --enabled true
    
    #
    # admin role 생성 및 할당

    echo "keystone role-create --name $ADMIN_ROLE"
    keystone role-create --name $ADMIN_ROLE       
    
    echo "keystone user-role-add --tenant $ADMIN_TENANT --user $ADMIN_USER --role $ADMIN_ROLE" 
    keystone user-role-add --tenant $ADMIN_TENANT --user $ADMIN_USER --role $ADMIN_ROLE

    #
    # member 사용자 생성 및 role 할당
    
    member_user_id=$(keystone --os-tenant-name $ADMIN_TENANT user-list | grep "$MEMBER_USER " | awk '{print $2}')
    if [ $member_user_id ]
    then
        printf "%s user already exists so delete it !!!\n" $MEMBER_USER        
        keystone user-delete $MEMBER_USER
    fi    
    echo "keystone user-create --name $MEMBER_USER --pass $PASSWORD --enabled true"
    keystone user-create --name $MEMBER_USER --pass $PASSWORD --enabled true
    
    #
    # member role 생성 및 할당

    echo "keystone role-create --name $MEMBER_ROLE"
    keystone role-create --name $MEMBER_ROLE       
    echo "keystone user-role-add --tenant $ADMIN_TENANT --user $MEMBER_USER --role $MEMBER_ROLE"  
    keystone user-role-add --tenant $ADMIN_TENANT --user $MEMBER_USER --role $MEMBER_ROLE

    echo ">>> check result ---------------------------------------------------------------"
    echo "keystone tenant-list"
    keystone tenant-list
    echo "# ------------------------------------------------------------------------------"
    echo "keystone user-list"
    keystone user-list
    echo "# ------------------------------------------------------------------------------"
    echo "keystone user-role-list"
    # LJG: 여기서 에러발생 -> keystone user-role-list    
    echo "# ------------------------------------------------------------------------------"
    
}


ctrl_keystone_service_create() {

    echo "
    # ------------------------------------------------------------------------------
    ### ctrl_keystone_service_create(keystone,nova,glance,cinder,neutron,ec2) !!!
    # ------------------------------------------------------------------------------"
    
    # Keystone Identity Service Endpoint
    svc_id=$(keystone service-list | grep "keystone " | awk '{print $2}')
    if [ $svc_id ]
    then
        printf "%s service already exists so delete it !!!\n" keystone        
        keystone service-delete keystone
    fi      
    echo "keystone service-create --name keystone --type identity --description 'OpenStack Identity Service'"
    keystone service-create --name keystone --type identity --description "OpenStack Identity Service"
        
    # OpenStack Compute Nova API Endpoint
    svc_id=$(keystone service-list | grep "nova " | awk '{print $2}')
    if [ $svc_id ]
    then
        printf "%s service already exists so delete it !!!\n" nova        
        keystone service-delete nova
    fi
    echo "keystone service-create --name nova --type compute --description 'OpenStack Compute Service'"
    keystone service-create --name nova --type compute --description "OpenStack Compute Service"
    
    # Glance Image Service Endpoint
    svc_id=$(keystone service-list | grep "glance " | awk '{print $2}')
    if [ $svc_id ]
    then
        printf "%s service already exists so delete it !!!\n" glance        
        keystone service-delete glance
    fi    
    echo "keystone service-create --name glance --type image --description 'OpenStack Image Service'"
    keystone service-create --name glance --type image --description "OpenStack Image Service"
    
    # Cinder Block Storage Endpoint
    svc_id=$(keystone service-list | grep "cinder " | awk '{print $2}')
    if [ $svc_id ]
    then
        printf "%s service already exists so delete it !!!\n" cinder        
        keystone service-delete cinder
    fi    
    echo "keystone service-create --name cinder --type volume --description 'OpenStack Block Storage Service'"
    keystone service-create --name cinder --type volume --description "OpenStack Block Storage Service"
    echo "keystone service-create --name=cinderv2 --type=volumev2 --description='OpenStack Block Storage v2 Service'"
    keystone service-create --name=cinderv2 --type=volumev2 --description="OpenStack Block Storage v2 Service"
    
    # Neutron Network Service Endpoint
    svc_id=$(keystone service-list | grep "neutron " | awk '{print $2}')
    if [ $svc_id ]
    then
        printf "%s service already exists so delete it !!!\n" neutron        
        keystone service-delete neutron
    fi
    echo "keystone service-create --name neutron --type network --description 'Neutron Network Service'"
    keystone service-create --name neutron --type network --description "Neutron Network Service"
    
    # OpenStack Compute EC2 API Endpoint
    svc_id=$(keystone service-list | grep "ec2 " | awk '{print $2}')
    if [ $svc_id ]
    then
        printf "%s service already exists so delete it !!!\n" ec2        
        keystone service-delete ec2
    fi
    echo "keystone service-create --name ec2 --type ec2 --description 'EC2 Service' "
    keystone service-create --name ec2 --type ec2 --description "EC2 Service"

    echo ">>> check result -------------------------------------------------------------------"
    keystone service-list
    echo "# ------------------------------------------------------------------------------"
}

ctrl_keystone_service_endpoint_create() {

    echo "
    # ------------------------------------------------------------------------------
    ### ctrl_keystone_service_endpoint_create(keystone,nova,glance,cinder,neutron,ec2) !!!
    # ------------------------------------------------------------------------------"
    
    #Keystone OpenStack Identity Service
    KEYSTONE_SERVICE_ID=$(keystone service-list | awk '/\ keystone\ / {print $2}')
    PUBLIC="http://$API_IP:5000/v2.0"
    ADMIN="http://$CTRL_HOST:35357/v2.0"
    INTERNAL=$ADMIN
    
    echo "keystone endpoint-create
        --region $REGION
        --service_id $KEYSTONE_SERVICE_ID
        --publicurl $PUBLIC
        --adminurl $ADMIN
        --internalurl $INTERNAL"        
    
    ask_continue_stop    
    
    keystone endpoint-create \
        --region $REGION \
        --service_id $KEYSTONE_SERVICE_ID \
        --publicurl $PUBLIC \
        --adminurl $ADMIN \
        --internalurl $INTERNAL
     
    #OpenStack Compute Nova API
    NOVA_SERVICE_ID=$(keystone service-list | awk '/\ nova\ / {print $2}')
    PUBLIC="http://$API_IP:8774/v2/\$(tenant_id)s"
    ADMIN="http://$CTRL_HOST:8774/v2/\$(tenant_id)s"
    INTERNAL=$ADMIN
    echo "keystone endpoint-create
        --region $REGION
        --service_id $NOVA_SERVICE_ID
        --publicurl $PUBLIC
        --adminurl $ADMIN
        --internalurl $INTERNAL"
    ask_continue_stop

    keystone endpoint-create \
        --region $REGION \
        --service_id $NOVA_SERVICE_ID \
        --publicurl $PUBLIC \
        --adminurl $ADMIN \
        --internalurl $INTERNAL
     
    #OpenStack Compute EC2 API
    EC2_SERVICE_ID=$(keystone service-list | awk '/\ ec2\ / {print $2}')
    PUBLIC="http://$API_IP:8773/services/Cloud"
    ADMIN="http://$CTRL_HOST:8773/services/Admin"
    INTERNAL=$ADMIN
    echo "keystone endpoint-create
        --region $REGION
        --service_id $EC2_SERVICE_ID
        --publicurl $PUBLIC
        --adminurl $ADMIN
        --internalurl $INTERNAL"
    ask_continue_stop

    keystone endpoint-create \
        --region $REGION \
        --service_id $EC2_SERVICE_ID \
        --publicurl $PUBLIC \
        --adminurl $ADMIN \
        --internalurl $INTERNAL
     
    #Glance Image Service
    GLANCE_SERVICE_ID=$(keystone service-list | awk '/\ glance\ / {print $2}')
    PUBLIC="http://$API_IP:9292/v2"
    ADMIN="http://$CTRL_HOST:9292/v2"
    INTERNAL=$ADMIN
    echo "keystone endpoint-create
        --region $REGION
        --service_id $GLANCE_SERVICE_ID
        --publicurl $PUBLIC
        --adminurl $ADMIN
        --internalurl $INTERNAL"
    ask_continue_stop
    
    keystone endpoint-create \
        --region $REGION \
        --service_id $GLANCE_SERVICE_ID \
        --publicurl $PUBLIC \
        --adminurl $ADMIN \
        --internalurl $INTERNAL
        
    #
    #Cinder Block Storage Service
    
    CINDER_SERVICE_ID=$(keystone service-list | awk '/\ cinder\ / {print $2}')
    PUBLIC="http://$API_IP:8776/v1/%(tenant_id)s"
    ADMIN="http://$CTRL_HOST:8776/v1/%(tenant_id)s"
    INTERNAL=$ADMIN
    
    echo "keystone endpoint-create
        --region $REGION
        --service_id $CINDER_SERVICE_ID
        --publicurl $PUBLIC
        --adminurl $ADMIN
        --internalurl $INTERNAL"
    ask_continue_stop
              
    keystone endpoint-create \
        --region $REGION \
        --service_id $CINDER_SERVICE_ID \
        --publicurl $PUBLIC \
        --adminurl $ADMIN \
        --internalurl $INTERNAL
    
    CINDER_SERVICE_ID_V2=$(keystone service-list | awk '/\ comderv2\ / {print $2}')
    PUBLIC="http://$API_IP:8776/v2/%(tenant_id)s"
    ADMIN="http://$CTRL_HOST:8776/v2/%(tenant_id)s"
    INTERNAL=$ADMIN 
    echo "keystone endpoint-create
        --region $REGION
        --service_id $CINDER_SERVICE_ID
        --publicurl $PUBLIC
        --adminurl $ADMIN
        --internalurl $INTERNAL"
    ask_continue_stop
            
    keystone endpoint-create \
        --region $REGION \
        --service_id $CINDER_SERVICE_ID \
        --publicurl $PUBLIC \
        --adminurl $ADMIN \
        --internalurl $INTERNAL
     
    #Neutron Network Service
    NEUTRON_SERVICE_ID=$(keystone service-list | awk '/\ network\ / {print $2}')
    PUBLIC="http://$API_IP:9696"
    ADMIN="http://$CTRL_HOST:9696"
    INTERNAL=$ADMIN
    echo "keystone endpoint-create
        --region $REGION
        --service_id $NEUTRON_SERVICE_ID
        --publicurl $PUBLIC
        --adminurl $ADMIN
        --internalurl $INTERNAL"
    ask_continue_stop
        
    keystone endpoint-create \
        --region $REGION \
        --service_id $NEUTRON_SERVICE_ID \
        --publicurl $PUBLIC \
        --adminurl $ADMIN \
        --internalurl $INTERNAL

    echo ">>> check result -------------------------------------------------------------------"
    keystone endpoint-list
    echo "# ------------------------------------------------------------------------------"
}


ctrl_keystone_service_account_role_create() {

    echo "
    # ------------------------------------------------------------------------------
    ### ctrl_keystone_service_account_role_create() !!!
    # ------------------------------------------------------------------------------"

    #Service Tenant
    keystone tenant-create --name service --description "Service Tenant" --enabled true
     
    SERVICE_TENANT_ID=$(keystone tenant-list | awk '/\ service\ / {print $2}')
    
    echo "keystone user-create --name nova --pass nova --tenant_id $SERVICE_TENANT_ID --email nova@localhost --enabled true"  
    keystone user-create --name nova --pass nova --tenant_id $SERVICE_TENANT_ID --email nova@localhost --enabled true
    echo "keystone user-create --name glance --pass glance --tenant_id $SERVICE_TENANT_ID --email glance@localhost --enabled true"
    keystone user-create --name glance --pass glance --tenant_id $SERVICE_TENANT_ID --email glance@localhost --enabled true
    echo "keystone user-create --name keystone --pass keystone --tenant_id $SERVICE_TENANT_ID --email keystone@localhost --enabled true"
    keystone user-create --name keystone --pass keystone --tenant_id $SERVICE_TENANT_ID --email keystone@localhost --enabled true
    echo "keystone user-create --name cinder --pass cinder --tenant_id $SERVICE_TENANT_ID --email cinder@localhost --enabled true"    
    keystone user-create --name cinder --pass cinder --tenant_id $SERVICE_TENANT_ID --email cinder@localhost --enabled true
    echo "keystone user-create --name neutron --pass neutron --tenant_id $SERVICE_TENANT_ID --email neutron@localhost --enabled true"
    keystone user-create --name neutron --pass neutron --tenant_id $SERVICE_TENANT_ID --email neutron@localhost --enabled true
    
    ADMIN_ROLE_ID=$(keystone role-list | awk '/\ admin\ / {print $2}') 
    #Assign the nova user the admin role in service tenant
    NOVA_USER_ID=$(keystone user-list | awk '/\ nova\ / {print $2}')
    echo "keystone user-role-add --user $NOVA_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID"
    keystone user-role-add --user $NOVA_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID
     
    #Assign the glance user the admin role in service tenant
    GLANCE_USER_ID=$(keystone user-list | awk '/\ glance\ / {print $2}')
    echo "keystone user-role-add --user $GLANCE_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID"
    keystone user-role-add --user $GLANCE_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID
     
    #Assign the keystone user the admin role in service tenant
    KEYSTONE_USER_ID=$(keystone user-list | awk '/\ keystone\ / {print $2}')
    echo "keystone user-role-add --user $KEYSTONE_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID"
    keystone user-role-add --user $KEYSTONE_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID
    
    #Assign the cinder user the admin role in service tenant 
    CINDER_USER_ID=$(keystone user-list | awk '/\ cinder \ / {print $2}')
    echo "keystone user-role-add --user $CINDER_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID"
    keystone user-role-add --user $CINDER_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID
     
    #Grant admin role to neutron service user
    NEUTRON_USER_ID=$(keystone user-list | awk '/\ neutron \ / {print $2}')
    echo "keystone user-role-add --user $NEUTRON_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID"
    keystone user-role-add --user $NEUTRON_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID
    
    echo ">>> check result ---------------------------------------------------------------"
    keystone tenant-list
    keystone user-list
    # LJG: 왜 에러가 발생할까? keystone user-role-list    
    echo "# ------------------------------------------------------------------------------"

}