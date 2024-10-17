#!/usr/bin/env bash

. /root/vars.sh

NAME_SH=bootloader.sh

# stop on errors
set -eu

packer_msg "Remove redundant fstab entries"
sed -i '\@^/dev/cdrom@d;\@^/dev/fd@d;\@/dev/usbdisk@d' /etc/fstab

packer_msg "Install the bootloader builder dependencies"
chroot pacman -S --noconfirm gptfdisk syslinux >/dev/null

packer_msg "Configure temporary syslinux for packer reboot"
chroot mkdir /boot/syslinux 
chroot mv /usr/share/syslinux/syslinux.cfg /boot/syslinux/syslinux.cfg
chroot syslinux-install_update -i -a -m >/dev/null
chroot /usr/bin/sed -e 's/root=\/dev\/sda./root='${PARTITION_ROOT////\\/}'/' \
-e 's/\(TIMEOUT[[:space:]]\)50/\110/' -i ${DIR_BOOT}/syslinux/syslinux.cfg
  
packer_msg "Configure u-root"
HOME=${DIR_HOME_ROOT}
chroot pacman -S --noconfirm git go moreutils sudo >/dev/null

packer_msg "Install the bootloader builder"
chroot /usr/bin/go install github.com/u-root/u-root@latest &>/dev/null

packer_msg "Generating the bootloader install script"
/usr/bin/install --mode=0755 /dev/null "${DIR_MNT_ROOT}${SCRIPT_CONFIG}"
tee "${DIR_MNT_ROOT}${SCRIPT_CONFIG}" &>/dev/null << EOF 
   git -C ${DIR_HOME_ROOT} clone https://github.com/u-root/u-root &>/dev/null
   cd ${DIR_HOME_ROOT}/u-root
   ${DIR_HOME_ROOT}/go/bin/u-root core boot &>/dev/null
   mv /tmp/initramfs.linux_amd64.cpio /boot/initramfs-linux.img
EOF

packer_msg "Entering bootloader install system"
chroot ${SCRIPT_CONFIG}
rm "${DIR_MNT_ROOT}${SCRIPT_CONFIG}"
HOME=${DIR_HOME_USER}
