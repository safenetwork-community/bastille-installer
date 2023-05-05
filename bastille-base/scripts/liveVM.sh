#!/usr/bin/bash

. /tmp/files/vars.sh

NAME_SH=liveVM.sh
GRUB=/etc/default/grub

# stop on errors
set -eu

echo ">>>> ${NAME_SH}: Lock root password.."
passwd -l root >/dev/null

echo ">>>> ${NAME_SH}: Modifying local settings.."
ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime
echo -s ${HOSTNAME_LIVEVM} | tee /etc/hostname >/dev/null

echo ">>>> ${NAME_SH}: Installing packages for commands used in provisioner scripts.."
/usr/bin/pacman --noconfirm -Sy gptfdisk pacman-contrib >/dev/null

echo ">>>> ${NAME_SH}: Reranking pacman mirrorslist.."
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup   
/usr/bin/rankmirrors /etc/pacman.d/mirrorlist-backup | tee /etc/pacman.d/mirrorlist >/dev/null
rm -rf /etc/pacman.d/mirrorlist-backup
