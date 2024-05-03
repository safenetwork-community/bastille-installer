#!/usr/bin/env bash

. /root/vars.sh

NAME_SH=pacman.sh

# stop on errors
set -eu

packer_msg "Installing databases"
chroot pacman -Sy >/dev/null

packer_msg "Installing basic packages"
chroot pacman -S --noconfirm base-devel cronie dhcpcd rsync openssh vi >/dev/null

packer_msg "Crontab rankmirrors every week"
chroot crontab -l &>/dev/null | { cat; echo "0 0 1 * * rankmirrors" >/dev/null; } | crontab -

/usr/bin/install --owner=root --group=root --mode=755 ${DIR_INIT}/sshd ${DIR_MNT_ROOT}${DIR_INIT}/sshd
