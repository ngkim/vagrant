#!/bin/bash

echo "
################################################################################
#
#   고객과 관련된 계정을 생성하고 권한을 부여한다.
#
################################################################################
"

function make_tenant() {

    GUEST_TENANT_ID=$(keystone tenant-list | grep "$GUEST_TENANT_NAME " | awk '{print $2}')
    if [ $GUEST_TENANT_ID ]; then
	    printf "%s tenant already exists !!!\n" $GUEST_TENANT_NAME
	    cli="keystone tenant-delete $GUEST_TENANT_NAME"
	    run_cli_as_admin $cli
    fi
    cli="keystone tenant-create --name=$GUEST_TENANT_NAME"
    run_cli_as_admin $cli
}


function make_user() {

    GUEST_USER_ID=$(keystone user-list | grep "$GUEST_USER_NAME " | awk '{print $2}')
    if [ $GUEST_USER_ID ]; then
	    printf "%s user already exists !!!\n" $GUEST_USER_NAME
	    cli="keystone user-delete $GUEST_USER_NAME"
        run_cli_as_admin $cli
    fi
    cli="keystone user-create --tenant=$GUEST_TENANT_NAME --name=$GUEST_USER_NAME --pass=$GUEST_USER_PASS --enabled true"
    run_cli_as_admin $cli

}


function member_role_create() {

    GUEST_ROLE_ID=$(keystone role-list | grep "$GUEST_ROLE_NAME " | awk '{print $2}')
    if [ $GUEST_ROLE_ID ]; then
        echo "keystone role $GUEST_ROLE_NAME exists !!!"
    else
        cli="keystone role-create --name $GUEST_ROLE_NAME"
        run_cli_as_admin $cli
    fi

}

function add_user_member_role() {
    
    GUEST_ROLE_ID=$(keystone user-role-list --tenant $GUEST_TENANT_NAME --user $GUEST_USER_NAME | grep "$GUEST_ROLE_NAME " | awk '{print $2}')
    if [ $GUEST_ROLE_ID ]; then
        echo "keystone role $GUEST_ROLE_NAME already added to user<<$GUEST_USER_NAME>> !!!"
    else
        cli="keystone user-role-add --tenant $GUEST_TENANT_NAME --user $GUEST_USER_NAME --role $GUEST_ROLE_NAME"
        run_cli_as_admin $cli
    fi
}

function add_tenant_default_security_group()
{
    #cli="nova --os-tenant-name $GUEST_TENANT_NAME --os-username $GUEST_USER_NAME --os-password $GUEST_USER_PASS
    #   secgroup-add-rule default tcp 22 22 0.0.0.0/0"
    #echo $cli;eval $cli
    
    cli="nova secgroup-add-rule default tcp 22 22 0.0.0.0/0"
    run_cli_as_user $cli

    cli="nova secgroup-add-rule default tcp 80 80 0.0.0.0/0"
    run_cli_as_user $cli

    cli="nova secgroup-add-rule default tcp 443 443 0.0.0.0/0"
    run_cli_as_user $cli

    cli="nova secgroup-add-rule default tcp 10443 10443 0.0.0.0/0"
    run_cli_as_user $cli
    
    cli="nova secgroup-add-rule default tcp 5001 5001 0.0.0.0/0"
    run_cli_as_user $cli

    cli="nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0"
    run_cli_as_user $cli

    cli="nova secgroup-list-rules default"
    run_cli_as_user $cli

}


function make_user_keypair()
{
    if [[ ! -d ./keys ]]; then
        mkdir ./keys
    fi
    
    GUEST_KEY_ID=$(nova --os-tenant-name $GUEST_TENANT_NAME --os-username $GUEST_USER_NAME --os-password $GUEST_USER_PASS keypair-list | grep "$GUEST_KEY " | awk '{print $2}')
    if [ $GUEST_KEY_ID ]; then
	    printf "%s key already exists !!!\n" $GUEST_KEY
	else
	    printf "%s key creates !!!\n" $GUEST_KEY
	    rm -f ./keys/${GUEST_KEY}*

	    ssh-keygen -t rsa -f ./keys/$GUEST_KEY -N ''	    
	    cli="nova keypair-add --pub-key ./keys/${GUEST_KEY_FILE} $GUEST_KEY"
        run_cli_as_user $cli
    fi

}
