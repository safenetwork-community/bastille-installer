#!/usr/bin/env bash

. /tmp/files/vars.sh

# stop on errors
set -e
set -x

# lock root password
passwd -l root

echo ">>>> configure-shared.sh: Setting pacman mirrors of liveVM.."
/usr/bin/pacman -Sy
/usr/bin/reflector --country Netherlands,Belgium --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
cat /etc/pacman.d/mirrorlist

echo ">>>> configure-shared.sh: Clearing partition table on ${DISK}.."
/usr/bin/sgdisk --zap ${DISK} | echo $?

echo ">>>> configure-shared.sh: Destroying magic strings and signatures on ${DISK}.."
/usr/bin/dd if=/dev/zero of=${DISK} bs=512 count=2048
/usr/bin/wipefs --all ${DISK}
