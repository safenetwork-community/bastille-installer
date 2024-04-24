#!/usr/bin/bash

. /root/vars.sh

NAME_SH=liveVM.sh
GRUB=/etc/default/grub

# stop on errors
set -eu

packer_msg "Lock root password"
/usr/bin/passwd -l root >/dev/null

packer_msg "Update the system clock"
/usr/bin/dinitctl start ntpd >/dev/null

packer_msg "Modifying local settings"
/usr/bin/ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime
echo ${NAME_LIVEVM_HOST} | tee /etc/hostname >/dev/null

packer_msg "Installing packages for commands used in provisioner scripts"
/usr/bin/pacman --noconfirm -Sy gptfdisk pacman-contrib >/dev/null

packer_msg "Reranking pacman mirrorslist"
/usr/bin/cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup   
/usr/bin/rankmirrors -v -n 5 /etc/pacman.d/mirrorlist-backup | tee /etc/pacman.d/mirrorlist >/dev/null
/usr/bin/rm -rf /etc/pacman.d/mirrorlist-backup
