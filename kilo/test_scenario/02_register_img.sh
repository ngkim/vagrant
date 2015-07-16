#!/bin/bash

source "./00_check_config.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

mkdir -p images

if [ ! -f images/${IMAGE_FILE} ]; then
	cmd="wget -O images/${IMAGE_FILE} ${IMAGE_LOCATION}"
	run_commands $cmd
fi

if [ -f images/${IMAGE_FILE} ]; then
	cmd="glance image-create --name=$IMAGE_LABEL --disk-format=$FILEFORMAT \
	--container-format=$CONTAINERFORMAT --visibility $ACCESSVALUE --progress < images/${IMAGE_FILE}"
	run_commands $cmd
fi
