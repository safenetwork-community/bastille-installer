#!/usr/bin/env bash

. /root/vars.sh

NAME_SH=mirrors.sh

# stop on errors
set -eu

echo "==> ${NAME_SH}: Reranking pacman mirrorlist.."
/usr/bin/artix-chroot ${ROOT_DIR} pacman -S --noconfirm pacman-contrib >/dev/null
/usr/bin/artix-chroot ${ROOT_DIR} cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup   
/usr/bin/artix-chroot ${ROOT_DIR} /usr/bin/rankmirrors -v -n 5 /etc/pacman.d/mirrorlist-backup | tee /etc/pacman.d/mirrorlist >/dev/null  
/usr/bin/artix-chroot ${ROOT_DIR} rm -rf /etc/pacman.d/mirrorlist-backup

echo "==> ${NAME_SH}: Installing cron.."
/usr/bin/artix-chroot ${ROOT_DIR} pacman -S --noconfirm cronie vi >/dev/null

echo "==> ${NAME_SH}: Crontab rankmirrors every week.."
/usr/bin/artix-chroot ${ROOT_DIR} crontab -l &>/dev/null | { cat; echo "0 0 1 * * rankmirrors" >/dev/null; } | crontab -
