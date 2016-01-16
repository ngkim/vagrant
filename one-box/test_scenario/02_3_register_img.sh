#!/bin/bash

source "./00_check_config.sh"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

register_image() {
  local _IMAGE_LABEL=$1
  local _IMAGE_FILE=$2

  if [ -f images/${_IMAGE_FILE} ]; then
    cmd="glance image-create --name ${_IMAGE_LABEL} --disk-format $FILEFORMAT \
#        --container-format $CONTAINERFORMAT --visibility $ACCESSVALUE --progress --file images/${_IMAGE_FILE}"
        --container-format $CONTAINERFORMAT --progress --file images/${_IMAGE_FILE}"
#        --container-format=$CONTAINERFORMAT --progress --file images/${_IMAGE_FILE}"
    run_commands $cmd
  fi
}

if [ -f images/${IMAGE_FILE} ]; then
  register_image $IMAGE_LABEL $IMAGE_FILE
  sleep 3
fi

if [ -f images/${UTM_IMAGE_FILE} ]; then
  register_image $UTM_IMAGE $UTM_IMAGE_FILE
  sleep 3
fi

if [ -f images/${WAF_IMAGE_FILE} ]; then
  register_image $WAF_IMAGE $WAF_IMAGE_FILE
  sleep 3
fi
