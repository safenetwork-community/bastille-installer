#!/usr/bin/env bash

. /root/vars.sh

NAME_SH=configure-virtualbox.sh

# stop on errors
set -eu

# VirtualBox Guest Additions
# https://wiki.archlinux.org/index.php/VirtualBox/Install_Arch_Linux_as_a_guest
packer_msg "Installing VirtualBox Guest Additions"
/usr/bin/pacman -S --noconfirm virtualbox-guest-utils-nox

packer_msg "Enabling VirtualBox Guest service"
/usr/bin/dinitctl enable vboxservice.service

packer_msg "Enabling RPC Bind service"
/usr/bin/dinitctl enable rpcbind.service

# Add groups for VirtualBox folder sharing
packer_msg "Enabling VirtualBox Shared Folders"
/usr/bin/usermod --append --groups vboxsf $NAME_USER 
