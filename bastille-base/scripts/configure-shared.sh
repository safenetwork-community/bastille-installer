#!/usr/bin/bash

. /tmp/files/vars.sh

NAME_SH=configure-shared.sh

# stop on errors
set -eu

# lock root password
passwd -l root

echo ">>>> ${NAME_SH}: Setting pacman mirrors of liveVM.."
/usr/bin/pacman -Sy
/usr/bin/reflector --country Netherlands,Belgium --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

echo ">>>> ${NAME_SH}: Clearing partition table on ${DISK}.."
/usr/bin/sgdisk --zap ${DISK}

echo ">>>> ${NAME_SH}: Destroying magic strings and signatures on ${DISK}.."
/usr/bin/dd if=/dev/zero of=${DISK} bs=512 count=2048
/usr/bin/wipefs --all ${DISK}
