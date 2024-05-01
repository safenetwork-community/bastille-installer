#!/usr/bin/env bash

. /root/vars.sh

NAME_SH=partitions.sh

# stop on errors
set -eu

packer_msg "Writing Filesystem types"
if [ "${TYPE_FS}" = "btrfs" ]; then
  mkfs.btrfs -m single -L ${LABEL_ROOT} ${PARTITION_ROOT} &>/dev/null
elif [ "${TYPE_FS}" = "ext4" ]; then
  mkfs.ext4 -O ^64bit -F -m 0 -q -L ${LABEL_ROOT} ${PARTITION_ROOT} &>/dev/null
fi

mkfs.fat -F32 ${PARTITION_BOOT} >/dev/null
fatlabel ${PARTITION_BOOT} ${LABEL_BOOT}

packer_msg "Mounting partitions"
/usr/bin/mount ${PARTITION_ROOT} ${DIR_MNT_ROOT}
/usr/bin/mkdir -p ${DIR_MNT_BOOT}
/usr/bin/mount ${PARTITION_BOOT} ${DIR_MNT_BOOT}
