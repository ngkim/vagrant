#!/bin/bash

source "./00_check_config.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

register_image() {
  local _IMAGE_LABEL=$1
  local _IMAGE_FILE=$2

  if [ -f image/${_IMAGE_FILE} ]; then
    cmd="glance image-create --name=${_IMAGE_LABEL} --disk-format=$FILEFORMAT \
        --container-format=$CONTAINERFORMAT --visibility $ACCESSVALUE --progress --file image/${_IMAGE_FILE}"
    run_commands $cmd
  fi
}

register_image $UTM_IMAGE $UTM_IMAGE_FILE
sleep 5
register_image $WAF_IMAGE $WAF_IMAGE_FILE
