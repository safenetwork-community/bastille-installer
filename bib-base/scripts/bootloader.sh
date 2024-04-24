#!/usr/bin/env bash

. /root/vars.sh

NAME_SH=bootloader.sh

# stop on errors
set -eu

packer_msg "Remove redundant fstab entries"
sed -i '\@^/dev/cdrom@d;\@^/dev/fd@d;\@/dev/usbdisk@d' /etc/fstab

packer_msg "Install the bootloader builder dependencies"
chroot pacman -S --noconfirm moreutils go gptfdisk syslinux >/dev/null

packer_msg "Configuring syslinux"
chroot syslinux-install_update -i -a -m
chroot /usr/bin/sed -e 's/root=\/dev\/sda./root='${PARTITION_ROOT////\\/}'/' \
  -e 's/\(TIMEOUT[[:space:]]\)50/\110/' -i ${DIR_BOOT}/syslinux/syslinux.cfg

# packer_msg "Install goenv."
# chroot ls -lha ~
# chroot curl -q -o ${DIR_HOME_ROOT} https://github.com/ankitcharolia/goenv/releases/latest/download/goenv-linux-amd64.tar.gz
# chroot mkdir ${DIR_HOME_ROOT}/goenv && tar -xzf goenv-linux-amd64.tar.gz -C ${DIR_HOME_ROOT}/goenv
# chroot install -o root -g root ${DIR_HOME_ROOT}/goenv/goenv /usr/bin/
# chroot goenv --install 1 &>/dev/null

# packer_msg "Install grub packages"
# chroot pacman -S --noconfirm grub >/dev/null

# packer_msg "Pre-configure grub"
# chroot sed -i 's/#GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/' /etc/default/grub

# packer_msg "Install grub"
# chroot grub-install --recheck ${DISK} 
# chroot ls -lha /boot
# chroot grub-mkconfig -o /boot/grub/grub.cfg
# chroot ls -lha /boot/grub
# chroot cat /etc/fstab 

# packer_msg "Install the bootloader builder"
# chroot go install github.com/u-root/u-root@latest >/dev/null
# chroot ls -lha ~

# packer_msg "Setup go version"
# chroot sponge .envrc <<'EOF'
# export GOROOT=~/.go/1.20.8
# EOF

# packer_msg "Install the bootloader"
# chroot ~/.go/bin/u-root core boot
# chroot mv /tmp/initramfs.linux_amd64.cpio /boot/initramfs-virt
# chroot ls -lha /boot
# chroot rm -rf ${DIR_HOME_ROOT}/u-root
