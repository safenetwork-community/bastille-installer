#!/usr/bin/env bash

NAME_SH=cleanup.sh

packer_msg() {
  echo "==> ${NAME_SH}: $@.."
}

# stop on errors
set -eu

packer_msg "Cleaning root dir"
/usr/bin/rm -rf /root/go 
/usr/bin/rm -rf /root/u-root 

packer_msg "Cleaning boot"
/usr/bin/pacman -Rcns --noconfirm syslinux linux linux-firmware >/dev/null

# Clean the pacman cache.
packer_msg "Cleaning pacman cache"
/usr/bin/pacman -Scc --noconfirm >/dev/null
