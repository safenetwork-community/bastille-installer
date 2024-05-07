#!/usr/bin/env bash

. /root/vars.sh

NAME_SH=setup.sh

# stop on errors
set -eu

packer_msg "Merge script system files"
/usr/bin/chown root: -R /tmp/rootdir
/usr/bin/rsync -a /tmp/rootdir/ ${DIR_MNT_ROOT}

packer_msg "Generating the system configuration script"
/usr/bin/install --mode=0755 /dev/null "${DIR_MNT_ROOT}${SCRIPT_CONFIG}"
tee "${DIR_MNT_ROOT}${SCRIPT_CONFIG}" &>/dev/null << EOF 
  echo "==> ${NAME_SH} Configuring hostname, timezone, and keymap.."
  echo '${HOSTNAME_BOX}' | tee /etc/hostname >/dev/null
  /usr/bin/ln -s /usr/share/zoneinfo/${TIMEZONE_BOX} /etc/localtime
  echo 'KEYMAP=${KEYMAP_BOX}' | tee /etc/vconsole.conf >/dev/null
  echo "==> ${NAME_SH} Configuring locale.."
  /usr/bin/sed -i 's/#${LANGUAGE_BOX}/${LANGUAGE_BOX}/' /etc/locale.gen
  /usr/bin/locale-gen >/dev/null
  echo "==> ${NAME_SH} Creating initramfs.."
  /usr/bin/mkinitcpio -p linux &>/dev/null
  echo "==> ${NAME_SH} Setting root pasword.."
  /usr/bin/usermod --password ${PASSWORD_ROOT} root
  echo "==> ${NAME_SH} Configure network.."
  /usr/bin/pacman -S  --noconfirm connman-dinit >/dev/null
  /usr/bin/ln -s /etc/dinit.d/connmand /etc/dinit.d/boot.d/
  echo "==> ${NAME_SH} Configure sshd.."
  /usr/bin/sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
  # Workaround for https://bugs.archlinux.org/task/58355 which prevents sshd to accept connections after reboot
  echo "==> ${NAME_SH} Adding workaround for sshd connection issue after reboot.."
  /usr/bin/pacman -S --noconfirm rng-tools >/dev/null
  /usr/bin/dinitctl enable rngd &>/dev/null
  echo "==> ${NAME_SH} Enable time synching.."
  /usr/bin/pacman -S --noconfirm ntp >/dev/null 
  /usr/bin/dinitctl enable ntpd &>/dev/null
  echo "==> ${NAME_SH} Modifying vagrant user.."
  /usr/bin/useradd --comment 'Vagrant User' --create-home --user-group ${GROUP_USER} >/dev/null
  /usr/bin/echo -e "${PASSWORD_USER}\n${PASSWORD_USER}" | /usr/bin/passwd ${NAME_USER} &>/dev/null
  echo "==> ${NAME_SH} Configuring sudo.."
  echo "Defaults env_keep += \"SSH_AUTH_SOCK\"" | tee /etc/sudoers.d/10_${NAME_USER} &>/dev/null
  echo "${NAME_USER} ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers.d/10_${NAME_USER} &>/dev/null
  /usr/bin/chmod 0440 /etc/sudoers.d/10_${NAME_USER}
  echo "==> ${NAME_SH} Install ${NAME_TITLE_APP} non-AUR dependencies.."
  /usr/bin/pacman -S --noconfirm wget parted >/dev/null
  /usr/bin/pacman -S --noconfirm cargo dialog dosfstools f2fs-tools polkit qemu-user-static-binfmt >/dev/null 
  echo "==> ${NAME_SH} Install ${NAME_TITLE_APP}.."
  /usr/bin/sudo -u ${NAME_USER} git -C ${DIR_HOME_USER} clone https://github.com/safenetwork-community/${NAME_FILE_APP}.git &>/dev/null
  /usr/bin/sudo -u ${NAME_USER} git -C ${DIR_APP} checkout -q `sudo -u ${NAME_USER} git -C ${DIR_APP} describe --tags >/dev/null`
  echo "==> ${NAME_SH} Install dependencies.."
  /usr/bin/pacman -S --noconfirm neovim >/dev/null
  echo "==> ${NAME_SH} Install a general IDE for the main user.."
  sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' &>/dev/null << E1F \
  | LV_BRANCH='release-1.3/neovim-0.9' sudo -u ${NAME_USER} \
  curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.3/neovim-0.9/utils/installer/install.sh \
  | sudo -u ${NAME_USER} bash &>/dev/null
n
n
y
E1F
  echo "==> ${NAME_SH} Setup bash aliases.."
  sudo -u ${NAME_USER} sponge -a ${DIR_HOME_USER}/.profile ${DIR_HOME_ROOT}/.profile <<'E1F'
  alias l='ls -lF --color'
  alias ll='l -a'
  alias h='history 25'
  alias j='jobs -l'
  alias vim='lvim'
E1F
  echo "==> ${NAME_SH} Cleaning up.."
    /usr/bin/pacman -Rcns --noconfirm base-devel gptfdisk go moreutils rsync >/dev/null
EOF

packer_msg "Entering packer_msg and configuring system"
chroot ${SCRIPT_CONFIG}
rm "${DIR_MNT_ROOT}${SCRIPT_CONFIG}"

packer_msg "Enable ssh access manually for box"
chroot ln -sf /etc/dinit.d/sshd /etc/dinit.d/boot.d/
/usr/bin/install --owner=root --group=root --mode=644 ${DIR_INIT}/sshd ${DIR_MNT_ROOT}${DIR_INIT}/sshd
/usr/bin/install --owner=root --group=root --mode=755 -D -t ${DIR_MNT_ROOT}${DIR_INIT}/scripts ${DIR_INIT}/scripts/sshd 

packer_msg "Creating ssh access for ${NAME_USER}"
/usr/bin/install --directory --owner=${NAME_USER} --group=${GROUP_USER} --mode=0700 ${DIR_MNT_ROOT}${DIR_SSH_USER}
/usr/bin/install --owner=${NAME_USER} --group=${GROUP_USER} --mode=0600 ${PATH_KEYS_USER} ${DIR_MNT_ROOT}${PATH_KEYS_USER}
chroot /usr/bin/chown -R ${NAME_USER}:${GROUP_USER} ${DIR_SSH_USER}

if [[ $TYPE_BUILDER_PACKER == "qemu" ]]; then
  packer_msg "Trimming partition sizes"
  /usr/bin/fstrim ${DIR_MNT_BOOT}
  /usr/bin/fstrim ${DIR_MNT_ROOT}
fi

packer_msg "Completing installation"
/usr/bin/umount ${DIR_MNT_BOOT}
/usr/bin/umount ${DIR_MNT_ROOT}
/usr/bin/rm -rf ${DIR_SSH_USER}

# Turning network interfaces down to make sure SSH session was dropped on host.
# More info at: https://www.packer.io/docs/provisioners/shell.html#handling-reboots
packer_msg "Turning down network interfaces and rebooting"
for i in $(/usr/bin/ip -o link show | /usr/bin/awk -F': ' '{print $2}'); do /usr/bin/ip link set ${i} down; done

packer_msg_exc "Installation complete"
/usr/bin/reboot
