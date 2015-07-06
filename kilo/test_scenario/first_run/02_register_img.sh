#!/bin/bash

IMAGELABEL="ubuntu12.04"
FILEFORMAT="qcow2"
CONTAINERFORMAT="bare"
ACCESSVALUE="True"
#IMAGEFILE="images/cirros-0.3.0-x86_64-disk.img"
IMAGEFILE="ubuntu12.04.img"
IMAGEFILE="precise-server-cloudimg-amd64-disk1.img"

if [ -z ${OS_AUTH_URL+x} ]; then
    source ~/openstack_rc
fi

#mkdir -p images

#echo "wget http://cdn.download.cirros-cloud.net/0.3.2/cirros-0.3.2-x86_64-disk.img -O $IMAGEFILE"
#wget http://cdn.download.cirros-cloud.net/0.3.2/cirros-0.3.2-x86_64-disk.img -O $IMAGEFILE

echo "glance image-create --name=$IMAGELABEL --disk-format=$FILEFORMAT \
  --container-format=$CONTAINERFORMAT --is-public=$ACCESSVALUE --progress < $IMAGEFILE"

glance image-create --name=$IMAGELABEL --disk-format=$FILEFORMAT \
  --container-format=$CONTAINERFORMAT --is-public=$ACCESSVALUE --progress < $IMAGEFILE
