set_config() {
	local CFG_FILE=$1
	local CFG_SECTION=$2
	local CFG_PARAM=$3
	local CFG_VALUE=$4
	
	VAL=`crudini --get --existing $CFG_FILE $CFG_SECTION $CFG_PARAM`
	if [ -z $VAL ]; then
		crudini --set $CFG_FILE $CFG_SECTION $CFG_PARAM $CFG_VALUE
	else				
		crudini --set --existing $CFG_FILE $CFG_SECTION $CFG_PARAM $CFG_VALUE
	fi
}

clear_config() {
	local CFG_FILE=$1
	local CFG_SECTION=$2
	local CFG_PARAM=$3
	
	VAL=`crudini --del --existing $CFG_FILE $CFG_SECTION $CFG_PARAM`
}
