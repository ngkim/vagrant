#! /bin/bash

ctrl_horizon_install() {

    echo '
    # ------------------------------------------------------------------------------
    ### ctrl_horizon_install!!!
    # ------------------------------------------------------------------------------'

    echo '  7.1 horizon service 설치'

    #Install dependencies
    apt-get install -y memcached
    
    #Install the dashboard (horizon)
    apt-get install -y openstack-dashboard
    dpkg --purge openstack-dashboard-ubuntu-theme

    echo '>>> check result------------------------------------------------------'
    dpkg -l | egrep "memcached|openstack-dashboard"    
    echo '# --------------------------------------------------------------------'

}

ctrl_horizon_configure() {
    
    echo '
    # ------------------------------------------------------------------------------
    ### ctrl_horizon_configure(${HORIZON_CONF}) !!!
    # ------------------------------------------------------------------------------'
    
    # LJG: 이 Horizon을 위한 API IP는 80, 443, 22번 포트만 오픈되야 함
    
    #Set default role
    # /etc/openstack-dashboard/local_settings.py
    sed -i "s/DEBUG = \"False\"/DEBUG = \"True\"/g" $HORIZON_CONF
    sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"${API_IP}\"/g" $HORIZON_CONF 
    
    #Move /horizon to /
    sed -i "s@LOGIN_URL.*@LOGIN_URL='/auth/login/'@g" $HORIZON_CONF 
    sed -i "s@LOGOUT_URL.*@LOGOUT_URL='/auth/logout/'@g" $HORIZON_CONF 
    sed -i "s@LOGIN_REDIRECT_URL.*@LOGIN_REDIRECT_URL='/'@g" $HORIZON_CONF 

    echo '>>> check result
    # ------------------------------------------------------------------------------'
    cat $HORIZON_CONF
    echo '
    # ------------------------------------------------------------------------------'
}




ctrl_apache_configure_restart() {
    
    echo '
    # ------------------------------------------------------------------------------
    ### ctrl_apache_configure_restart(${APACHE_CONF}) !!!
    # ------------------------------------------------------------------------------'

#Apache Conf
cat > ${APACHE_CONF} << EOF
# ------------------------------------------------------------------------------

WSGIScriptAlias / /usr/share/openstack-dashboard/openstack_dashboard/wsgi/django.wsgi
WSGIDaemonProcess horizon user=horizon group=horizon processes=3 threads=10
WSGIProcessGroup horizon

Alias /static /usr/share/openstack-dashboard/openstack_dashboard/static/

<Directory /usr/share/openstack-dashboard/openstack_dashboard/wsgi>
    Order allow,deny
    Allow from all
</Directory>
# ------------------------------------------------------------------------------
EOF

    echo '>>> check result
    # ------------------------------------------------------------------------------'
    cat $APACHE_CONF
    echo '
    # ------------------------------------------------------------------------------'
    
    service apache2 restart
}


