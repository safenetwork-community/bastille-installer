#!/usr/bin/env bash

. /tmp/files/vars.sh

NAME_SH=setup.sh

# stop on errors
set -eu

echo ">>>> ${NAME_SH}: Generating the system configuration script.."
/usr/bin/install --mode=0755 /dev/null "${ROOT_DIR}${CONFIG_SCRIPT}"

CONFIG_SCRIPT_SHORT=`basename "$CONFIG_SCRIPT"`
tee "${ROOT_DIR}${CONFIG_SCRIPT}" &>/dev/null << EOF
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Configuring hostname, timezone, and keymap.."
  echo '${HOSTNAME_BOX}' | tee /etc/hostname
  /usr/bin/ln -s /usr/share/zoneinfo/${TIMEZONE_BOX} /etc/localtime
  echo 'KEYMAP=${KEYMAP_BOX}' > /etc/vconsole.conf
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Configuring locale.."
  /usr/bin/sed -i 's/#${LANGUAGE_BOX}/${LANGUAGE_BOX}/' /etc/locale.gen
  /usr/bin/locale-gen
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Creating initramfs.."
  /usr/bin/mkinitcpio -p linux &>/dev/null
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Setting root pasword.."
  /usr/bin/usermod --password ${USER_PASSWORD} root
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Configuring network.."
  # Disable systemd Predictable Network Interface Names and revert to traditional interface names
  # https://wiki.archlinux.org/index.php/Network_configuration#Revert_to_traditional_interface_names
  /usr/bin/ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules
  /usr/bin/dinitctl enable dhcpcd@eth0.service
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Configuring sshd.."
  /usr/bin/sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
  /usr/bin/dinitctl enable sshd
  # Workaround for https://bugs.archlinux.org/task/58355 which prevents sshd to accept connections after reboot
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Adding workaround for sshd connection issue after reboot.."
  /usr/bin/pacman -S --noconfirm rng-tools >/dev/null
  /usr/bin/dinitctl enable rngd
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Enable time synching.."
  /usr/bin/pacman -S --noconfirm ntp
  /usr/bin/dinitctl enable ntpd 
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Installing ${ISCR} non-AUR dependencies.."
  /usr/bin/pacman -S --noconfirm wget git parted >/dev/null 
  /usr/bin/pacman -S --noconfirm dialog dosfstools f2fs-tools polkit qemu-user-static-binfmt >/dev/null
  # Vagrant user apparently created through basestrap for Artix Linux.
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Modifying vagrant user.."
  /usr/bin/useradd --password ${TEMP_PASSWORD} --comment 'Vagrant User' -d /home/${USERNAME} --user-group ${GROUPNAME}
  /usr/bin/echo -e "${USER_PASSWORD}\n${USER_PASSWORD}" | /usr/bin/passwd ${USERNAME}
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Configuring sudo.."
  echo "Defaults env_keep += \"SSH_AUTH_SOCK\"" | tee /etc/sudoers.d/10_${USERNAME}
  echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers.d/10_${USERNAME}
  /usr/bin/chmod 0440 /etc/sudoers.d/10_${USERNAME}
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Cleaning up.."
  /usr/bin/pacman -Rcns --noconfirm gptfdisk
EOF

echo ">>>> ${NAME_SH}: Entering chroot and configuring system.."
/usr/bin/artix-chroot ${ROOT_DIR} ${CONFIG_SCRIPT}
rm "${ROOT_DIR}${CONFIG_SCRIPT}"

echo ">>>> ${NAME_SH}: Creating ssh access for ${USERNAME}.."
/usr/bin/install --directory --owner=${USERNAME} --group=${GROUPNAME} --mode=0700 ${ROOT_DIR}${SSH_DIR}
/usr/bin/install --owner=${USERNAME} --group=${GROUPNAME} --mode=0600 ${A_KEYS_PATH} ${ROOT_DIR}${SSH_DIR}

# http://comments.gmane.org/gmane.linux.arch.general/48739
echo ">>>> ${NAME_SH}: Adding workaround for shutdown race condition.."
/usr/bin/install --mode=0644 ${FILES_DIR}/poweroff.timer "${ROOT_DIR}/etc/systemd/system/poweroff.timer"

echo ">>>> ${NAME_SH}: Trimming partition sizes.."
/usr/bin/fstrim ${BOOT_DIR}
/usr/bin/fstrim ${ROOT_DIR}

echo ">>>> ${NAME_SH}: Completing installation.."
/usr/bin/umount ${BOOT_DIR}
/usr/bin/umount ${ROOT_DIR}
/usr/bin/rm -rf ${SSH_DIR}

# Turning network interfaces down to make sure SSH session was dropped on host.
# More info at: https://www.packer.io/docs/provisioners/shell.html#handling-reboots
echo '==> Turning down network interfaces and rebooting'
for i in $(/usr/bin/ip -o link show | /usr/bin/awk -F': ' '{print $2}'); do /usr/bin/ip link set ${i} down; done
# /usr/bin/reboot
echo ">>>> ${NAME_SH}: Installation complete!"
