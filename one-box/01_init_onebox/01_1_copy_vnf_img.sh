#!/bin/bash

source "./00_check_config.sh"

source "./onebox.cfg"

copy_vnf_image() {
  VNF_TYPE=$1
  VNF_VENDOR=$2
  VNF_IMAGE=$3

  VNF_IMG_LOCATION="$IMAGE_ROOT/${VNF_TYPE}/${VNF_VENDOR}/images/${VNF_IMAGE}"
  print_title "VNF_IMG_LOCATION= $VNF_IMG_LOCATION"
  if [ ! -f $VNF_IMG_LOCATION ]; then
    echo "scp $IMAGE_ROOT:$VNF_IMG_LOCATION $VNF_IMG_LOCATION"
    scp $IMAGE_ROOT:$VNF_IMG_LOCATION $VNF_IMG_LOCATION
  else
    echo "$VNF_IMG_LOCATION exists."
  fi
  sleep 1
}

copy_vnf_image ${UTM_VNF_TYPE} ${UTM_VENDOR} ${UTM_IMAGE}
copy_vnf_image ${WAF_VNF_TYPE} ${WAF_VENDOR} ${WAF_IMAGE}
copy_vnf_image ${APC_VNF_TYPE} ${APC_VENDOR} ${APC_IMAGE}
copy_vnf_image ${NMS_VNF_TYPE} ${NMS_VENDOR} ${NMS_IMAGE}
