WORK_HOME=/root/one-box

source "$WORK_HOME/config/default.cfg"
source "$WORK_HOME/include/print_util.sh"
source "$WORK_HOME/include/12_config.sh"
source "$WORK_HOME/include/command_util.sh"

source "./onebox.cfg"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi


