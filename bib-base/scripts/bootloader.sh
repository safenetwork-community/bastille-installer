#!/bin/ash
set -euxo pipefail

NAME_SH=bootloader.sh
USER=bas

#echo "==> ${NAME_SH}: Remove initial efi grub and all it\'s configurations.."
#apk del --purge grub-efi
#apk del --purge grub

#echo "==> ${NAME_SH}: Remove EFI boot options.."
#apk add efibootmgr
#efibootmgr \
#  | sed -nE 's,^Boot([0-9A-F]{4}).*,\1,gp' \
#  | xargs -I% efibootmgr --quiet --delete-bootnum --bootnum %

ls -lha /boot
ls -lha /boot/grub
cat /boot/grub/grub.cfg

sed -i '\@^/dev/cdrom@d;\@^/dev/fd@d;\@/dev/usbdisk@d' /etc/fstab

echo "==> ${NAME_SH}: Rebuild initramfs.."
mkinitfs

echo "==> ${NAME_SH}: New initramfs for QEMU.."
mkinitfs -o /tmp/initramfs-virt
chmod 777 /tmp/initramfs-virt

echo "==> ${NAME_SH}: New initramfs for Linuxboot.."
cp /tmp/initramfs-virt /tmp/initramfs-virt.gz
zcat /tmp/initramfs-virt.gz | cpio -id /tmp/initramfs-virt.gz
chmod 777 /tmp/initramfs-virt.gz

#grub-mkconfig -o /boot/grub/grub.cfg
#sleep 300
