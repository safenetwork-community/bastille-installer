#!/usr/bin/env bash

. /root/vars.sh

echo ">>>> partition-btrfs-lbios.sh: Writing Filesystem types.."
mkfs.btrfs -L BOHKS_EQAHM ${ROOT_PARTITION}
mkfs.fat -F32 ${BOOT_PARTITION}

echo ">>>> partition-btrfs-lbios.sh: Mounting partitions.."
/usr/bin/mount ${ROOT_PARTITION} ${ROOT_DIR}
/usr/bin/mkdir -p ${BOOT_DIR}
/usr/bin/mount ${BOOT_PARTITION} ${BOOT_DIR}

echo ">>>> partition-btrfs-lbios.sh: Bootstrapping the base installation.."
/usr/bin/pacstrap ${ROOT_DIR} base btrfs-progs `pacman -Qq linux`

echo ">>>> partition-btrfs-lbios.sh: Updating pacman mirrors base installation.."
/usr/bin/arch-chroot ${ROOT_DIR} pacman -S --noconfirm reflector 
/usr/bin/arch-chroot ${ROOT_DIR} reflector --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
tee /etc/xdg/reflector/reflector.conf &>/dev/null <<EOF
--latest 5 
--protocol https
--sort rate
--save /etc/pacman.d/mirrorlist
EOF
/usr/bin/arch-chroot ${ROOT_DIR} systemctl enable reflector.timer

echo ">>>> partition-btrfs-lbios.sh: Installing databases.."
/usr/bin/arch-chroot ${ROOT_DIR} pacman -Sy

# Need to install netctl as well: https://github.com/archlinux/arch-boxes/issues/70
# Can be removed when Vagrant's Arch plugin will use systemd-networkd: https://github.com/hashicorp/vagrant/pull/11400
echo ">>>> partition-btrfs-lbios.sh: Installing basic packages.."
/usr/bin/arch-chroot ${ROOT_DIR} pacman -S --noconfirm sudo gptfdisk openssh grub dhcpcd netctl

echo ">>>> partition-btrfs-lbios.sh: Generating the filesystem table.."
/usr/bin/genfstab -U ${ROOT_DIR} | tee -a "${ROOT_DIR}/etc/fstab"

echo ">>>> partition-btrfs-lbios.sh: Configuring grub.."
/usr/bin/arch-chroot ${ROOT_DIR} grub-install --force --target=i386-pc --recheck --boot-directory=/boot ${DISK}
/usr/bin/arch-chroot ${ROOT_DIR} grub-mkconfig -o /boot/grub/grub.cfg

echo ">>>> partition-btrfs-lbios.sh: Generating the system configuration script.."
/usr/bin/install --mode=0755 /dev/null "${ROOT_DIR}${CONFIG_SCRIPT}"
