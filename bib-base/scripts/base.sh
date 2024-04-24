#!/usr/bin/env bash

. /root/vars.sh

NAME_SH=base.sh

# stop on errors
set -eu

packer_msg "Installing base system"
bootstrap base &>/dev/null

packer_msg "Reranking pacman mirrorlist"
chroot pacman -S --noconfirm pacman-contrib >/dev/null
chroot cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup   
chroot /usr/bin/rankmirrors -v -n 5 /etc/pacman.d/mirrorlist-backup | tee /etc/pacman.d/mirrorlist >/dev/null  
chroot rm -rf /etc/pacman.d/mirrorlist-backup

if [ "${TYPE_FS}" = "btrfs" ]; then
  packer_msg "Installing Btrfs filesystem"
  chroot pacman -S --noconfirm btrfs-progs >/dev/null
fi

packer_msg "Installing kernel packages"
chroot pacman -S --noconfirm linux linux-firmware >/dev/null

packer_msg "Generating the filesystem table"
/usr/bin/fstabgen -U ${DIR_MNT_ROOT} | tee -a "${DIR_MNT_ROOT}/etc/fstab" >/dev/null
