#!/usr/bin/env bash

. /tmp/files/vars.sh

NAME_SH=partition-ext4-efi.sh

# stop on errors
set -eu

echo ">>>> ${NAME_SH}: Writing Filesystem types.."
mkfs.ext4 -L BOHKS_BAZ ${ROOT_PARTITION}
mkfs.fat -F32 ${BOOT_PARTITION}

echo ">>>> ${NAME_SH}: Mounting partitions.."
/usr/bin/mount ${ROOT_PARTITION} ${ROOT_DIR}
/usr/bin/mkdir -p ${BOOT_DIR}
/usr/bin/mount ${BOOT_PARTITION} ${BOOT_DIR}

echo ">>>> ${NAME_SH}: Bootstrapping the base installation.."
/usr/bin/pacstrap ${ROOT_DIR} base `pacman -Qq linux`

echo ">>>> ${NAME_SH}: Updating pacman mirrors base installation.."
/usr/bin/arch-chroot ${ROOT_DIR} pacman -S --noconfirm reflector 

/usr/bin/arch-chroot ${ROOT_DIR} reflector --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
tee /etc/xdg/reflector/reflector.conf &>/dev/null <<EOF
--latest 5 
--protocol https
--sort rate
--save /etc/pacman.d/mirrorlist
EOF
/usr/bin/arch-chroot ${ROOT_DIR} systemctl enable reflector.timer

echo ">>>> ${NAME_SH}: Installing databases.."
/usr/bin/arch-chroot ${ROOT_DIR} pacman -Sy

echo ">>>> ${NAME_SH}: Installing basic packages.."
/usr/bin/arch-chroot ${ROOT_DIR} pacman -S --noconfirm sudo gptfdisk openssh grub efibootmgr dhcpcd netctl

echo ">>>> ${NAME_SH}: Generating the filesystem table.."
/usr/bin/genfstab -U ${ROOT_DIR} | tee -a "${ROOT_DIR}/etc/fstab" >/dev/null

echo ">>>> ${NAME_SH}: Installing grub.."
/usr/bin/arch-chroot ${ROOT_DIR} grub-install --target=x86_64-efi --efi-directory=${ESP_DIR} --bootloader-id=GRUB >/dev/null
/usr/bin/arch-chroot ${ROOT_DIR} grub-mkconfig -o /boot/grub/grub.cfg

#/usr/bin/arch-chroot ${ROOT_DIR} mkdir ${ESP_DIR}/EFI/boot
#/usr/bin/arch-chroot ${ROOT_DIR} install ${ESP_DIR}/EFI/GRUB/grubx64.efi ${ESP_DIR}/EFI/boot/bootx64.efi

echo ">>>> ${NAME_SH}: Delete unnecessary boots.."
/usr/bin/arch-chroot ${ROOT_DIR} efibootmgr
# /usr/bin/arch-chroot ${ROOT_DIR} efibootmgr -b 0001 -B >/dev/null
# /usr/bin/arch-chroot ${ROOT_DIR} efibootmgr -b 0002 -B >/dev/null
# /usr/bin/arch-chroot ${ROOT_DIR} efibootmgr -b 0004 -B >/dev/null
# /usr/bin/arch-chroot ${ROOT_DIR} efibootmgr -b 0005 -B >/dev/null

echo ">>>> ${NAME_SH}: Generating the system configuration script.."
/usr/bin/install --mode=0755 /dev/null "${ROOT_DIR}${CONFIG_SCRIPT}"
