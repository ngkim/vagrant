#!/bin/bash

echo "
################################################################################
#
#   고객과 관련된 계정을 생성하고 권한을 부여한다.
#
################################################################################
"



function host_aggregate_old() {

    cli="nova aggregate-create $HOST_AGGR_NAME $AVAILABILITY_ZONE"    
    run_cli_as_admin $cli
    
    cli="nova aggregate-add-host $HOST_AGGR_NAME controller"    
    run_cli_as_admin $cli
    
    cli="nova aggregate-add-host $HOST_AGGR_NAME cnode01"    
    run_cli_as_admin $cli
    
    cli="nova aggregate-add-host $HOST_AGGR_NAME cnode02"    
    run_cli_as_admin $cli

}

function host_aggregate() {

    cli="nova aggregate-create $HOST_AGGR_NAME $AVAILABILITY_ZONE"    
    run_cli_as_admin $cli
    
    cli="nova aggregate-add-host $HOST_AGGR_NAME anode"    
    run_cli_as_admin $cli
    
    cli="nova aggregate-add-host $HOST_AGGR_NAME cnode01"    
    run_cli_as_admin $cli
    
    cli="nova aggregate-add-host $HOST_AGGR_NAME cnode02"    
    run_cli_as_admin $cli

}

function admin_default_security_group()
{   
    
    cli="nova secgroup-add-rule default tcp 22 22 0.0.0.0/0"
    run_cli_as_admin $cli

    cli="nova secgroup-add-rule default tcp 80 80 0.0.0.0/0"
    run_cli_as_admin $cli

    cli="nova secgroup-add-rule default tcp 443 443 0.0.0.0/0"
    run_cli_as_admin $cli

    cli="nova secgroup-add-rule default tcp 5001 5001 0.0.0.0/0"
    run_cli_as_admin $cli

    cli="nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0"
    run_cli_as_admin $cli

    cli="nova secgroup-list-rules default"
    run_cli_as_admin $cli

}

function add_ssh_pool_security_group()
{
        
    
    cli="nova secgroup-create ssh_pool 'allow ssh_port_pool for test using global_mgmt_net vm'"
    run_cli_as_admin $cli
    
    cli="nova secgroup-add-rule ssh_pool tcp 20022 20122 0.0.0.0/24"
    run_cli_as_admin $cli    
    
    cli="nova secgroup-add-rule ssh_pool tcp 22 22 0.0.0.0/0"
    run_cli_as_admin $cli

    cli="nova secgroup-add-rule ssh_pool tcp 80 80 0.0.0.0/0"
    run_cli_as_admin $cli

    cli="nova secgroup-add-rule ssh_pool tcp 443 443 0.0.0.0/0"
    run_cli_as_admin $cli

    cli="nova secgroup-add-rule ssh_pool tcp 5001 5001 0.0.0.0/0"
    run_cli_as_admin $cli

    cli="nova secgroup-add-rule ssh_pool icmp -1 -1 0.0.0.0/0"
    run_cli_as_admin $cli

    cli="nova secgroup-list-rules ssh_pool"
    run_cli_as_admin $cli
}

function admin_keypair()
{
    
    ADMIN_KEY_ID=$(nova keypair-list | grep "$ADMIN_KEY " | awk '{print $2}')
    if [ $ADMIN_KEY_ID ]; then
	    printf "%s key already exists !!!\n" $ADMIN_KEY
	else
	    printf "%s key creates !!!\n" $ADMIN_KEY
	    rm -f ${ADMIN_KEY}*

	    ssh-keygen -t rsa -f $ADMIN_KEY -N ''	    
	    cli="nova keypair-add --pub-key $ADMIN_KEY_FILE $ADMIN_KEY"
        run_cli_as_admin $cli
    fi

}