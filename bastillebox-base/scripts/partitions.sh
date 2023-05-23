#!/usr/bin/env bash

. /root/vars.sh

NAME_SH=partitions.sh

# stop on errors
set -eu

echo "==> ${NAME_SH}: Writing Filesystem types.."
mkfs.ext4 -O ^64bit -F -m 0 -q -L ${ROOT_LABEL} ${ROOT_PARTITION} &>/dev/null
mkfs.fat -F32 ${BOOT_PARTITION} >/dev/null
fatlabel ${BOOT_PARTITION} ${BOOT_LABEL}

echo "==> ${NAME_SH}: Mounting partitions.."
/usr/bin/mount ${ROOT_PARTITION} ${ROOT_DIR}
/usr/bin/mkdir -p ${BOOT_DIR}
/usr/bin/mount ${BOOT_PARTITION} ${BOOT_DIR}
