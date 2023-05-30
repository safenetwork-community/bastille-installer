#!/usr/bin/env bash

. /root/vars.sh

NAME_SH=base.sh

# stop on errors
set -eu

echo "==> ${NAME_SH}: Installing base system.."
/usr/bin/basestrap ${ROOT_DIR} base &>/dev/null

if [ "${FS_TYPE}" = "btrfs" ]; then
  /usr/bin/basestrap ${ROOT_DIR} btrfs-progs
fi

echo "==> ${NAME_SH}: Reranking pacman mirrorlist.."
/usr/bin/artix-chroot ${ROOT_DIR} pacman -S --noconfirm pacman-contrib >/dev/null
/usr/bin/artix-chroot ${ROOT_DIR} cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup   
/usr/bin/artix-chroot ${ROOT_DIR} /usr/bin/rankmirrors -v -n 5 /etc/pacman.d/mirrorlist-backup | tee /etc/pacman.d/mirrorlist >/dev/null  
/usr/bin/artix-chroot ${ROOT_DIR} rm -rf /etc/pacman.d/mirrorlist-backup

echo "==> ${NAME_SH}: Installing cron.."
/usr/bin/artix-chroot ${ROOT_DIR} pacman -S --noconfirm cronie vi >/dev/null

echo "==> ${NAME_SH}: Crontab rankmirrors every week.."
/usr/bin/artix-chroot ${ROOT_DIR} crontab -l &>/dev/null | { cat; echo "0 0 1 * * rankmirrors" >/dev/null; } | crontab -
echo "==> ${NAME_SH}: Installing kernel.."
/usr/bin/basestrap ${ROOT_DIR} linux linux-firmware >/dev/null

echo "==> ${NAME_SH}: Installing base development and init.."
/usr/bin/basestrap ${ROOT_DIR} base-devel ${INIT_TYPE} elogind-${INIT_TYPE} &>/dev/null

echo "==> ${NAME_SH}: Generating the filesystem table.."
/usr/bin/fstabgen -U ${ROOT_DIR} | tee -a "${ROOT_DIR}/etc/fstab" >/dev/null
