#!/usr/bin/env bash

. /tmp/files/vars.sh

# stop on errors
set -eu

NAME_SH=tables.sh

echo ">>>> ${NAME_SH}: Clearing partition table on ${DISK}.."
/usr/bin/sgdisk --zap ${DISK} >/dev/null

echo ">>>> ${NAME_SH}: Destroying magic strings and signatures on ${DISK}.."
/usr/bin/dd if=/dev/zero of=${DISK} bs=512 count=2048 &>/dev/null
/usr/bin/wipefs --all ${DISK} >/dev/null

echo ">>>> ${NAME_SH}: Formatting disk.."
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | gdisk ${DISK} >/dev/null
  o
  y
  n
  1

  +${BOOT_SIZE}
  ef02
  n
  2
   
   
  8304
  p
  w
  y
  q
EOF
