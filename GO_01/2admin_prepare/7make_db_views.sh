#!/bin/bash

echo "
################################################################################
#
#   Install Openstack Util DB View
#
################################################################################
"

vw_vm_trace_query="
	CREATE VIEW vw_vm_trace AS  
	    SELECT
	        a.display_name AS vm_name,
	        b.action       AS ACTION,
	        c.event        AS event,
	        c.start_time   AS start_time,
	        c.finish_time  AS finish_time,
	        c.result       AS result,
	        c.traceback    AS traceback
	    FROM 
	        instances a,
	        instance_actions b,
	        instance_actions_events c
	    WHERE a.uuid = b.instance_uuid
	        AND b.id = c.action_id
	
	    UNION 
	
	    SELECT
	        a.display_name  AS vm_name,
	        b.host          AS HOST,
	        '#instance fault',
	        b.created_at    AS created_at,
	        b.deleted_at    AS deleted_at,
	        b.message       AS message,
	        b.details       AS details
	    FROM 
	        instances a,
	        instance_faults b
	    WHERE a.uuid = b.instance_uuid
"

vw_vm_inventory_query="

CREATE VIEW vw_vm_inventory AS    
    /*
     openstack detail inventory 구하기
    
        기본적으로 vm을 중심으로 관련된 데이터를 최대로 구해 이 질의문 하나에 대부분의 관계를 파악할 수 있도록 한다.
    
        volume, network등과 같은 레코드들은 하나의 vm에 여러개의 레코드가 나올수 있어 깔끔하게 표시하기 어렵지만
        group 함수들을 이용하여 최대한 표현하도록 한다. (예, 볼류갯수, 볼륨 정보 리스트 등)
        
        그리고 project와 관련된 정보도 상당히 다양하지만 기본적으로 힌트를 얻기위해 securitygroup과 같은 정보를 보여줌으로서
        이 질의문을 보는 사람이 관련성을 파악할 수 있는 힌트를 제공하자.
    
    주의 사항(LJG):
        1. group 함수를 잘 사용해야 한다. vm과 1:n의 관계인데 1:1인줄 알고 join을 하면 더 많은 열이 구해지므로
           항상 instances 테이블과 갯수를 비교하면 질의를 수행하는 습관이 필요, 나중에 디버깅하려면 골치아프다....
        2. group_concat, concat 함수내의 필드중에 하나라도 null이 있으면 전체가 null이 나온다.
        3. group_concat는 from 절에 outer join을 만들고 그 테이블을 사용하면 결과레코드가 하나만 나온다. 
           즉, select 절에서 개별 row에 적용해야 한다는 얘기
    */
    
    SELECT
        ni.availability_zone                                                        AS vm_zone,
        ni.host                                                                     AS vm_host,
        ni.hostname                                                                 AS vm_name,
        ni.uuid                                                                     AS vm_uuid,
        
        ni.created_at                                                               AS vm_create_dt,
        -- DATE_ADD(ni.created_at, INTERVAL 9 HOUR) as vm_create_dt2,
        -- vm_host info 
        /*
            SELECT 
                hypervisor_hostname,
                vcpus*5 AS total_vcpu,
                vcpus_used AS used_vcpu,
                vcpus_used/(vcpus*5) *100 AS 'percent_vcpu(%)',
                memory_mb AS 'total_mm(MB)', 
                memory_mb_used AS 'used_mm(MB)', 
                memory_mb_used/memory_mb*100 AS 'percent_mm(%)'
            FROM 
                nova.compute_nodes
            -- where hypervisor_hostname=''
            ORDER BY memory_mb_used/memory_mb*100 DESC, vcpus_used/(vcpus*5) *100 DESC;
        */
             -- json형식으로 포맷팅
            (SELECT
                CONCAT( '[',     
                    GROUP_CONCAT( CONCAT('{ host total_vcpu(x5): ',ncn.vcpus*5,'}'
                        -- ,' host total_base_vcpu: ',ncn.vcpus
                        ,', { host used_vcpu: ',ncn.vcpus_used,'}'
                        ,', { percent_vcpu(%): ', FORMAT(ncn.vcpus_used/(vcpus*5) * 100, 1),'}'
                        ,', { total_mm_MB: ',ncn.memory_mb,'}'
                        ,', { used_mm_MB: ',ncn.memory_mb_used,'}'
                        ,', { percent_mm(%): ',FORMAT((ncn.memory_mb_used/ncn.memory_mb)*100,1),'}'
                        ) SEPARATOR ',')
                ,']' )
             FROM
                 nova.compute_nodes    AS ncn
             WHERE 
                 ni.host = ncn.hypervisor_hostname)                                AS vm_host_info,
                    
        kp.name                                                                    AS vm_project_name,
        
        -- project 관련 compute quota & quota usages
        (SELECT
                CONCAT( '[',
                    GROUP_CONCAT( CONCAT('{', nq.resource,': ', nq.hard_limit, '}') SEPARATOR ', ')
                ,']' )
             FROM
                nova.quotas AS nq
             WHERE
                ni.project_id = nq.project_id
                AND nq.resource IN ('instances','cores','ram') )                   AS vm_project_compute_quotas,

        (SELECT
                CONCAT( '[',
                GROUP_CONCAT( CONCAT('{', nqu.resource,': ', nqu.in_use, '}') SEPARATOR ', ')
                ,']' )
             FROM
                nova.quota_usages AS nqu
             WHERE
                ni.project_id = nqu.project_id
                AND nqu.resource IN ('instances','cores','ram') )                  AS vm_project_compute_quota_usage,
    
        -- project 관련 storage quota & quota usages
        (SELECT
                CONCAT( '[',
                GROUP_CONCAT( CONCAT('{', cq.resource,': ', cq.hard_limit, '}') SEPARATOR ', ')
                ,']' )
             FROM
                cinder.quotas AS cq
             WHERE
                ni.project_id = cq.project_id )                                    AS vm_project_volume_quotas,

        (SELECT
                CONCAT( '[',
                GROUP_CONCAT( CONCAT('{', cqu.resource,' -> ', cqu.in_use, '}') SEPARATOR ', ')
                ,']' )
             FROM
                cinder.quota_usages AS cqu
             WHERE
                ni.project_id = cqu.project_id )                                   AS vm_project_volume_quotas_usage,
        
        -- project 관련 network quota & quota usages
        (SELECT
            CONCAT( '[',
                GROUP_CONCAT( CONCAT('{', nq.resource,': ', nq.limit, '}') SEPARATOR ', ')
            ,']' )
             FROM
                neutron.quotas AS nq
             WHERE
                ni.project_id = nq.tenant_id )                                    AS vm_project_network_quotas,
        /*
        (SELECT
                GROUP_CONCAT( CONCAT(nqu.resource,': ', nqu.in_use) SEPARATOR ', ')
             FROM
                neutron.quota_usages AS nqu
             WHERE
                ni.project_id = qqu.project_id )                                   AS vm_project_network_quotas_usage,
        */
        
        -- tennant(project)관련 security group info
        (SELECT
                GROUP_CONCAT( qsg.name SEPARATOR ', ')
             FROM
                neutron.securitygroups AS qsg
             WHERE
                ni.project_id = qsg.tenant_id )                                    AS vm_sequrity_group_info,
    
        ku.name                                                                    AS vm_user_name,
        
        -- user key pair info
        -- LJG: 조심 ! 하나의 user가 여러개의 key pair를 가지는 경우가 있슴
        
        (SELECT
            GROUP_CONCAT( nkp.fingerprint SEPARATOR ', ')
         FROM
            nova.key_pairs AS nkp
         WHERE
            ni.user_id = nkp.user_id )                                             AS vm_user_keypair_fingerprints,
            
        (SELECT
                GROUP_CONCAT( nkp.public_key SEPARATOR ', ')
             FROM
                nova.key_pairs AS nkp
             WHERE
                ni.user_id = nkp.user_id )                                         AS vm_user_keypair_public_key,
                
        -- ku.password as user_password,
        -- ku.extra as user_info,
    
        ni.display_description                                                     AS vm_desc,    
        -- ni.power_state AS vm_power_state_code,
        CASE ni.power_state
            WHEN '0' THEN 'inactive'
            WHEN '1' THEN 'active'
            ELSE '-'
        END                                                                        AS vm_power_state,
        
        ni.vm_state                                                                AS vm_state,
        nit.name                                                                   AS vm_instance_type,
        -- nit.vcpus,
        -- nit.memory_mb,
        -- nit.swap,        
        -- nit.vcpu_weight, -- 이건 뭘까??
        -- nit.rxtx_factor,
        -- nit.root_gb,
        
        ni.vcpus                                                                   AS vm_vcpus,    
        ni.memory_mb                                                               AS vm_memory_MB,    
    
        -- vm's volume info
        
        (SELECT
            -- concat(count(*), '-', sum(vol.size))
            COUNT(*)
         FROM
            cinder.volumes AS vol
         WHERE
            vol.deleted_at IS NULL AND
            ni.uuid = vol.instance_uuid) AS vm_vol_count,
    
        (SELECT
            SUM(vol.size)
         FROM
            cinder.volumes AS vol
         WHERE
            vol.deleted_at IS NULL AND
            ni.uuid = vol.instance_uuid)                                           AS vm_vol_size_sum_GB,
    
        (SELECT
            CONCAT( '[',
                GROUP_CONCAT( CONCAT( '{ vol_name: ', 
                    cv.display_name, '}, {size(GB): ', 
                    cv.size, '}, {Loc: ', 
                    cv.provider_location,'}') SEPARATOR ', ') 
            ,']' )
         FROM
            cinder.volumes AS cv
         WHERE
            cv.deleted_at IS NULL 
            AND ni.uuid = cv.instance_uuid)                                        AS vm_vol_infos,

        /*
        (SELECT
                GROUP_CONCAT(vol.display_name SEPARATOR '-')
             FROM
                cinder.volumes AS vol
             WHERE
                vol.deleted_at IS NULL AND
                ni.uuid = vol.instance_uuid) AS vm_vol_names,
        
        (SELECT
                GROUP_CONCAT(vol.size SEPARATOR '-')
             FROM
                cinder.volumes AS vol
             WHERE
                vol.deleted_at IS NULL AND
                ni.uuid = vol.instance_uuid) AS 'vm_vol_sizes(GB)',
        
        (SELECT
                GROUP_CONCAT(vol.provider_location SEPARATOR '-')
             FROM
                cinder.volumes AS vol
             WHERE
                vol.deleted_at IS NULL AND
                ni.uuid = vol.instance_uuid) AS 'vm_vol_locs',
        */
        
        -- vm system_meta info -> json formatting
        (SELECT    
            CONCAT( '[',            
            GROUP_CONCAT( CONCAT('{', nism.key,': ', nism.value, '}') SEPARATOR ', ')
            ,']' )
        FROM             
            nova.instance_system_metadata AS nism
        WHERE
            ni.uuid = nism.instance_uuid)                                          AS vm_system_meta_infos,
        
        -- vm's network info
        niic.network_info                                                          AS vm_network_info,
        
        (SELECT
            COUNT(*)
         FROM
            neutron.ports AS qp
         WHERE            
            ni.uuid = qp.device_id)                                                AS vm_nic_count,

        (SELECT
            GROUP_CONCAT(qp.mac_address SEPARATOR ' ')
         FROM
            neutron.ports AS qp
         WHERE            
            ni.uuid = qp.device_id)                                                AS vm_macs,
             
        (SELECT            
            GROUP_CONCAT(qn.name SEPARATOR ' ')
         FROM
            neutron.ports AS qp,
            neutron.networks AS qn
         WHERE            
            ni.uuid = qp.device_id
            AND qp.network_id = qn.id)                                             AS vm_networks,
                
        (SELECT
            GROUP_CONCAT(qp.device_owner SEPARATOR ' ')
         FROM
            neutron.ports AS qp
         WHERE            
            ni.uuid = qp.device_id)                                                AS vm_devices_owners,
   
        (SELECT
            GROUP_CONCAT(qi.ip_address SEPARATOR ' ')
         FROM
            neutron.ports AS qp,
            neutron.ipallocations AS qi
         WHERE            
            ni.uuid = qp.device_id        
            AND qp.id = qi.port_id )                                               AS vm_net_ips,
        
        (SELECT
            GROUP_CONCAT(qs.cidr SEPARATOR ' ')
         FROM
            neutron.ports AS qp,
            neutron.ipallocations AS qi,
            neutron.subnets AS qs
         WHERE            
            ni.uuid = qp.device_id        
            AND qp.id = qi.port_id
            AND qi.subnet_id = qs.id
        )                                                                          AS vm_net_cidrs,
        
        (SELECT
            -- GROUP_CONCAT(IFNULL(qs.gateway_ip,'null') SEPARATOR '-')
            GROUP_CONCAT(qs.gateway_ip SEPARATOR ' ')
         FROM
            neutron.ports AS qp,
            neutron.ipallocations AS qi,
            neutron.subnets AS qs
         WHERE            
            ni.uuid = qp.device_id        
            AND qp.id = qi.port_id
            AND qi.subnet_id = qs.id
        )                                                                          AS vm_net_gw_ips,
        
        ni.hostname                                                                AS vm_hostname,    
        ni.launched_at                                                                AS vm_start_dt,
        ni.root_device_name                                                        AS vm_root,
        
        -- ni.task_state as vm_task_state,
        -- ni.node as vm_node,
        
        gi.name                                                                    AS image_name,
        gi.size/1000000000                                                         AS image_size_GB
        
    FROM 
        nova.instances AS ni
        LEFT OUTER JOIN keystone.project AS kp
            ON ni.project_id = kp.id
    
        LEFT OUTER JOIN keystone.user AS ku
            ON ni.user_id = ku.id
    
        LEFT OUTER JOIN glance.images AS gi
            ON ni.image_ref = gi.id
    
        LEFT OUTER JOIN nova.instance_info_caches AS niic
            ON (ni.uuid = niic.instance_uuid AND niic.deleted_at IS NULL)
        
        LEFT OUTER JOIN nova.instance_types AS nit
            ON ni.instance_type_id = nit.id
                        
    WHERE 
        ni.deleted_at IS NULL
        -- AND ni.hostname = 'pos-dev-ktis'
        
    ORDER BY vm_zone, vm_host, vm_name, vm_create_dt
"

vw_vm_ips_query="
    CREATE VIEW vw_vm_ips AS  
        SELECT
            vw_vm_inventory.vm_name    AS vm_name,
            vw_vm_inventory.vm_net_ips AS vm_net_ips
        FROM nova.vw_vm_inventory
"

    
function create_openstack_db_views()
{
    echo '
    ----------------------------------------------------------------------------
        create_openstack_util_views !!!
    ----------------------------------------------------------------------------
    '
	#echo "drop view vw_vm_trace"
	#mysql -uroot -pohhberry3333 -h localhost -B -s -e "use nova;drop view vw_vm_trace"
	echo '#---------------------------------------------------------------------'
	echo $vw_vm_trace_query
	echo '#---------------------------------------------------------------------'
	mysql -uroot -pohhberry3333 -h localhost -B -s -e "use nova;$vw_vm_trace_query"


	#echo "drop view vw_vm_inventory"
	#mysql -uroot -pohhberry3333 -h localhost -B -s -e "use nova;drop view vw_vm_inventory"
	#echo '#---------------------------------------------------------------------'
	#echo $vw_vm_inventory_query
	#echo '#---------------------------------------------------------------------'
	mysql -uroot -pohhberry3333 -h localhost -B -s -e "use nova;$vw_vm_inventory_query"
	
	echo '#---------------------------------------------------------------------'
    echo $vw_vm_ips_query
    echo '#---------------------------------------------------------------------'
    mysql -uroot -pohhberry3333 -h localhost -B -s -e "use nova;$vw_vm_ips_query"
    
	echo '#---------------------------------------------------------------------'
	mysql -uroot -pohhberry3333 -h localhost -B -s -e "use nova;show table status;" | grep vw
    echo '#---------------------------------------------------------------------'        
}