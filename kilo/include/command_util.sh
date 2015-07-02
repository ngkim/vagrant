blue=$(tput setaf 4)
green=$(tput setaf 2)
red=$(tput setaf 1)
normal=$(tput sgr0)

print_msg() {
  msg=$*

  echo -e ${blue}$msg${normal}
}

print_msg_high() {
  msg=$*

  echo -e ${red}$msg${normal}
}

function run_commands() {
    commands=$*

    echo -e ${green}${commands}${normal}
    eval $commands
}

function run_commands_return() {
    commands=$*

    echo -e ${green}${commands}${normal}
    RET=`eval $commands`
}

function call_restapi_json() {
    commands=$*

    echo -e ${green}${commands}${normal}
    eval $commands 2> /dev/null | python -m json.tool
    echo 
}
