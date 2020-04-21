#!/bin/bash

# you can provide a fixed destination dev and source image
# defaults are DEV=/dev/mmcblk0 and IMAGE=look for a OpenWRT image
DEV=$2
IMAGE=$1

NOTIFY="notify-send --urgency=low -i `[ $? = 0 ] && echo terminal || echo error` FlashingDONE"

if [ $# -lt 2 ]; then    
    echo "usage:"
    echo "$0 src_img dst_block_device"
    exit 1
fi

# check whether the image is uncompressed
UNCOMPRESSED=`gzip -l ${IMAGE} 2>&1| grep "not in gzip format"|wc -l`
if [ ${UNCOMPRESSED} -eq 1 ]; then
    IMAGE_SIZE=`wc -c <"${IMAGE}"`
else
    IMAGE_SIZE=`gzip -l ${IMAGE} |grep -v "ratio" |awk '{print $2}'`
fi
echo "Flashing ${IMAGE_SIZE} bytes from ${IMAGE} to ${DEV}"

if [ `echo ${DEV}|cut -c 1-11` = "/dev/mmcblk" ];
then
  PART_PREFIX="p"
else
  PART_PREFIX=""
fi

if [ -b ${DEV} ]; 
then 
  sudo umount ${DEV}${PART_PREFIX}1
  sudo umount ${DEV}${PART_PREFIX}2
  if [ ${UNCOMPRESSED} -eq 1 ]; then
  	cat ${IMAGE} | pv -s ${IMAGE_SIZE} | sudo dd status=noxfer oflag=sync  bs=4M of=${DEV}  ; ${NOTIFY}
  else
  	zcat ${IMAGE} | pv -s ${IMAGE_SIZE} | sudo dd status=noxfer oflag=sync  bs=4M of=${DEV}  ; ${NOTIFY}
  fi
  # kick the bell to let the user know we finished
  echo -ne '\007'
else 
  echo File $DEV is not a block device ; 
  exit 1
fi

