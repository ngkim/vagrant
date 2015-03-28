#!/bin/bash

echo "
################################################################################
#
#   change <<$OS_TENANT_NAME>> project quotas
#
################################################################################
"

get_tenant_id _tenant_id $OS_TENANT_NAME
get_user_id   _user_id   $OS_TENANT_NAME $OS_USERNAME

function update_admin_nova_quota() {
    echo 
    echo "# default nova quota for $OS_TENANT_NAME"    

    cli="nova quota-show --tenant $_tenant_id"
    # +-----------------------------+-------+
    # | Quota                       | Limit |
    # +-----------------------------+-------+
    # | instances                   | 10    |
    # | cores                       | 20    |
    # | ram                         | 51200 |
    # | floating_ips                | 10    |
    # | fixed_ips                   | -1    |
    # | metadata_items              | 128   |
    # | injected_files              | 5     |
    # | injected_file_content_bytes | 10240 |
    # | injected_file_path_bytes    | 255   |
    # | key_pairs                   | 100   |
    # | security_groups             | 10    |
    # | security_group_rules        | 20    |
    # +-----------------------------+-------+
    echo $cli;eval $cli

    # 기본적으로 10배씩 뻥뛰기 해주자 !!!
    # --fixed_ips 100
    # --injected_file_content_bytes 102400
    # --injected_file_path_bytes 2550
    # --key_pairs 1000
    # --security_groups 100
    # --security_group_rules 100
    cli="
    nova quota-update
        --instances 100
        --cores 500
        --ram 512000
        --floating-ips 100        
        --metadata_items 1280
        --injected_files 500
        $_tenant_id
    "
    echo $cli; eval $cli


    echo 
    echo "# changed nova quota for $OS_TENANT_NAME"    
    cli="nova quota-show --tenant $_tenant_id"
    echo $cli; eval $cli

    # nova quota-update --user $_admin_id --fixed_ips 100 $_tenant_id

}


function update_admin_neutron_quota() {
	
	echo 
    echo "# default neutron quota for $OS_TENANT_NAME"    
    
	show_cli="neutron quota-show --tenant-id $_tenant_id"
	echo $show_cli;	eval $show_cli
    # +---------------------+-------+
    # | Field               | Value |
    # +---------------------+-------+
    # | floatingip          | 50    |
    # | network             | 10    |
    # | port                | 50    |
    # | router              | 10    |
    # | security_group      | 10    |
    # | security_group_rule | 100   |
    # | subnet              | 10    |
    # +---------------------+-------+
	
	update_cli="
    neutron quota-update --tenant-id $_tenant_id
        --floatingip 500
        --network 100
        --port 5000
        --router 100        
        --security_group 100
        --security_group_rule 1000        
    "
	
	echo $update_cli; eval $update_cli	
	
	echo
	echo $show_cli
	
	
}

function update_admin_cinder_quota() {
    
    echo 
    echo "# default cinder quota for $OS_TENANT_NAME"
    
    show_cli="cinder quota-show $OS_TENANT_NAME"
    echo $show_cli; eval $show_cli
    
    # gigabytes |  1000 |
    # snapshots |   10  |
    # volumes  |   10 
    
    update_cli="
    cinder quota-update 
        --gigabytes 10000
        --snapshots 100
        --volumes 100
        $_tenant_id        
    "
    
    echo $update_cli; eval $update_cli    
 
    echo
    echo "# changed cinder quota for $OS_TENANT_NAME"
    
    echo $show_cli; eval $show_cli   
}
