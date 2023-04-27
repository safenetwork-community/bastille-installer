#!/usr/bin/env bash

. /tmp/files/vars.sh

NAME_SH=partition-ext4-efi.sh

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

/usr/bin/arch-chroot ${ROOT_DIR} grub-install --target=x86_64-efi --efi-directory=${ESP_DIR} --bootloader-id=GRUB
/usr/bin/arch-chroot ${ROOT_DIR} grub-mkconfig -o /boot/grub/grub.cfg

echo ">>>> ${NAME_SH}: Generating the filesystem table.."
/usr/bin/genfstab -U ${ROOT_DIR} | tee -a "${ROOT_DIR}/etc/fstab" >/dev/null

echo ">>>> ${NAME_SH}: Generating the system configuration script.."
/usr/bin/install --mode=0755 /dev/null "${ROOT_DIR}${CONFIG_SCRIPT}"
