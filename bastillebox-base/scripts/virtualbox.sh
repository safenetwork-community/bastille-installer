#!/usr/bin/bash -x

. /root/vars.sh

NAME_SH=configure-virtualbox.sh

# stop on errors
set -eu

# VirtualBox Guest Additions
# https://wiki.archlinux.org/index.php/VirtualBox/Install_Arch_Linux_as_a_guest
echo "==> ${NAME_SH}: Installing VirtualBox Guest Additions and NFS utilities.."
/usr/bin/pacman -S --noconfirm virtualbox-guest-utils-nox nfs-utils

echo "==> ${NAME_SH}: Enabling VirtualBox Guest service.."
/usr/bin/systemctl enable vboxservice.service

echo "==> ${NAME_SH}: Enabling RPC Bind service.."
/usr/bin/systemctl enable rpcbind.service

# Add groups for VirtualBox folder sharing
echo "==> ${NAME_SH}: Enabling VirtualBox Shared Folders.."
/usr/bin/usermod --append --groups vagrant,vboxsf vagrant
