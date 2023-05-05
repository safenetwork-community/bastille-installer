#!/usr/bin/env bash

. /tmp/files/vars.sh

NAME_SH=partitions.sh

# stop on errors
set -eu

echo ">>>> ${NAME_SH}: Writing Filesystem types.."
mkfs.ext4 -L BOHKS_BAZ ${ROOT_PARTITION} &>/dev/null
mkfs.fat -F32 ${BOOT_PARTITION} >/dev/null
fatlabel ${BOOT_PARTITION} ESP

echo ">>>> ${NAME_SH}: Mounting partitions.."
/usr/bin/mount ${ROOT_PARTITION} ${ROOT_DIR}
/usr/bin/mkdir -p ${BOOT_DIR}
/usr/bin/mount ${BOOT_PARTITION} ${BOOT_DIR}

echo ">>>> ${NAME_SH}: Update the system clock.."
dinitctl start ntpd >/dev/null

echo ">>>> ${NAME_SH}: Installing base system.."
/usr/bin/basestrap ${ROOT_DIR} base base-devel ${INIT_TYPE} elogind-${INIT_TYPE} &>/dev/null

if [ "${FS_TYPE}" = "btrfs" ]; then
  /usr/bin/basestrap ${ROOT_DIR} btrfs-progs
fi

echo ">>>> ${NAME_SH}: Installing kernel.."
/usr/bin/basestrap ${ROOT_DIR} linux linux-firmware >/dev/null

echo ">>>> ${NAME_SH}: Generating the filesystem table.."
/usr/bin/fstabgen -U ${ROOT_DIR} | tee -a "${ROOT_DIR}/etc/fstab" >/dev/null

echo ">>>> ${NAME_SH}: Reranking pacman mirrorlist.."
/usr/bin/artix-chroot ${ROOT_DIR} pacman -S --noconfirm pacman-contrib >/dev/null
/usr/bin/artix-chroot ${ROOT_DIR} cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup   
/usr/bin/artix-chroot ${ROOT_DIR} /usr/bin/rankmirrors /etc/pacman.d/mirrorlist-backup | tee /etc/pacman.d/mirrorlist >/dev/null  
/usr/bin/artix-chroot ${ROOT_DIR} rm -rf /etc/pacman.d/mirrorlist-backup
/usr/bin/artix-chroot ${ROOT_DIR} ls -lha /dev
/usr/bin/artix-chroot ${ROOT_DIR} ln -s /dev/dinitctl /run/dinitctl
/usr/bin/artix-chroot ${ROOT_DIR} /usr/bin/dinitctl list 
/usr/bin/artix-chroot ${ROOT_DIR} /usr/bin/dinitctl enable rankmirrors.timer

echo ">>>> ${NAME_SH}: Installing databases.."
/usr/bin/artix-chroot ${ROOT_DIR} pacman -Sy >/dev/null

echo ">>>> ${NAME_SH}: Installing basic packages.."
/usr/bin/artix-chroot ${ROOT_DIR} pacman -S --noconfirm gptfdisk openssh dhcpcd >/dev/null
