#!/usr/bin/env bash

if [[ $PACKER_BUILDER_TYPE == "qemu" ]]; then
  DISK='/dev/vda'
else
  DISK='/dev/sda'
fi

COUNTRIES='Netherlands,Belgium'
VDA_BOOT=/run/archiso/bootmnt

# stop on errors
# set -xe

# lock root password
passwd -l root

echo ">>>> setup.sh: Setting pacman mirrors of liveVM.."
/usr/bin/reflector --country ${COUNTRIES} --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

echo ">>>> setup.sh: Performing installation.."
/usr/bin/archinstall --script /tmp/files/packer-archlinux.py
echo ">>>> setup.sh: Completed installation.."

echo ">>>> setup.sh: - Begin Arch Installer - "
/usr/bin/cat /var/log/archinstall/install.log
echo ">>>> setup.sh: - End Arch Installer -"

exit

echo ">>>> setup.sh: disabling password for sudoers.."
/usr/bin/chroot /mnt/archinstall sed -i 's/ALL$/NOPASSWD:ALL/' /etc/sudoers.d/10_mai
echo ">>>> setup.sh: disabled password for sudoers."

/usr/bin/systemctl reboot
