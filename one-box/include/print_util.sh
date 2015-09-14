blue=$(tput setaf 4)
green=$(tput setaf 2)
red=$(tput setaf 1)
normal=$(tput sgr0)

print_title() {
	TITLE=$*
	echo -e "${blue}==================================================================${normal}"
	echo -e "${blue}  $TITLE ${normal}"
	echo -e "${blue}==================================================================${normal}"
}

print_msg() {
  msg=$*

  echo -e ${blue}$msg${normal}
}

print_msg_high() {
  msg=$*

  echo -e ${red}$msg${normal}
}