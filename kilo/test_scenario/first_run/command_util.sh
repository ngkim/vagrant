blue=$(tput setaf 4)
green=$(tput setaf 2)
red=$(tput setaf 1)
normal=$(tput sgr0)

function run_commands() {
    if [ -z ${OS_AUTH_URL+x} ]; then
    	source ~/openstack_rc
	fi
	
    commands=$*

	echo -e ${green}${commands}${normal}
	eval $commands    
    echo 
}