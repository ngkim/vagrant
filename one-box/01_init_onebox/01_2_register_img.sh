#!/bin/bash

source "./00_check_config.sh"

source "./onebox.cfg"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/admin-openrc.sh
fi

register_image() {
  local _IMAGE_LABEL=$1
  local _IMAGE_FILE=$2

  if [ -f ${_IMAGE_FILE} ]; then
    cmd="glance image-create --name ${_IMAGE_LABEL} --disk-format $FILEFORMAT \
        --container-format $CONTAINERFORMAT --visibility $ACCESSVALUE --progress --file ${_IMAGE_FILE}"
#        --container-format=$CONTAINERFORMAT --progress --file images/${_IMAGE_FILE}"
    run_commands $cmd
  fi
}

vnf_image_register() {
  VNF_LABEL=$1
  VNF_IMAGE=$2

  echo "VNF_LABEL= ${VNF_LABEL}"
  echo "VNF_IMAGE= ${VNF_IMAGE}"
  register_image $VNF_LABEL $VNF_IMAGE
  sleep 2
}

VNF_LABEL="${UTM_VNF_TYPE}-${UTM_NAME}-${UTM_VENDOR}-${UTM_VERSION}"
VNF_IMAGE="${VNF_IMAGE_ROOT}/${UTM_VNF_TYPE}/${UTM_VENDOR}/images/${UTM_IMAGE}"
vnf_image_register ${VNF_LABEL} ${VNF_IMAGE}

VNF_LABEL="${WAF_VNF_TYPE}-${WAF_NAME}-${WAF_VENDOR}-${WAF_VERSION}"
VNF_IMAGE="${VNF_IMAGE_ROOT}/${WAF_VNF_TYPE}/${WAF_VENDOR}/images/${WAF_IMAGE}"
vnf_image_register ${VNF_LABEL} ${VNF_IMAGE}

VNF_LABEL="${APC_VNF_TYPE}-${APC_NAME}-${APC_VENDOR}-${APC_VERSION}"
VNF_IMAGE="${VNF_IMAGE_ROOT}/${APC_VNF_TYPE}/${APC_VENDOR}/images/${APC_IMAGE}"
vnf_image_register ${VNF_LABEL} ${VNF_IMAGE}
