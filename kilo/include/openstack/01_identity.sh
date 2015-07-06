
env_setup() {
	export OS_TOKEN=${ADMIN_TOKEN}
	export OS_URL=http://controller:35357/v2.0
}

create_project() {
	local _ID=$1
	local _NAME=$2
	
	openstack project create --description "${_NAME} Project" ${_ID}
}

create_user() {
	local _ID=$1
	local _PWD=$2
	
	openstack user create --password ${_PWD} ${_ID}
}

create_role() {
	local _ID=$1
	
	openstack role create $_ID
}

add_user_to_role() {
	local _USR=$1
	local _PRJ=$2	
	local _ROLE=$3
	
	openstack role add --project ${_PRJ} --user ${_USR} ${_ROLE}
}