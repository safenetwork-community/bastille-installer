#!/bin/ash

set -euxo pipefail
NAME_SH='initLiveVM.sh'

NAME='bas'
USER='bas'
PASS='bas'
GROUP='bas'
PUBLIC_KEY=id_${NAME}.pub
PRIVATE_KEY=id_${NAME}
SSH_DIR=/home/${USER}/.ssh
A_KEYS=${SSH_DIR}/authorized_keys
LOCAL_IP='10.0.2.2'

CFG_SSH=/etc/ssh/sshd_config
DOASD_DIR=/etc/doas.d/

BOOT_DEVICE='/dev/sda'
APKREPOSOPTS="http://mirrors.dotsrc.org/alpine/v3.18/main"

echo "==> ${NAME_SH}: Update package list.."
echo ${APKREPOSOPTS} | tee -a /etc/apk/repositories
apk update

# install btrfs
apk add btrfs-progs

# install to local disk.
cat >answers <<EOF
APKREPOSOPTS=${APKREPOSOPTS}
DISKOPTS="-s 0 -m sys ${BOOT_DEVICE}"
DNSOPTS=""
HOSTNAMEOPTS="-n alpine"
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
"
KEYMAPOPTS="us us"
NTPOPTS="-c chrony"
PROXYOPTS="none"
ROOTFS="btrfs"
SSHDOPTS="-c openssh"
TIMEZONEOPTS="-z UTC"
USE_EFI=1
USEROPTS="-a ${USER}"
EOF
ERASE_DISKS="${BOOT_DEVICE}" ROOTFS="btrfs" \
setup-alpine -e -f ${PWD}/answers >/dev/null

passwd -u ${USER}

# install the efi boot manager.
apk add efibootmgr
# show the boot options.
# efibootmgr -v
# remove all the boot options.
efibootmgr \
  | sed -nE 's,^Boot([0-9A-F]{4}).*,\1,gp' \
  | xargs -I% efibootmgr --quiet --delete-bootnum --bootnum %
  # create the boot option.
efibootmgr \
  -c \
  -d "${BOOT_DEVICE}" \
  -p 1 \
  -L Alpine \
  -l '\EFI\alpine\grubx64.efi'

# mount device
mount -t btrfs "${BOOT_DEVICE}2" /mnt

# configure the vagrant user.
chroot /mnt ash <<-EOF
set -euxo pipefail

# configure doas to allow the wheel group members to use root permissions
# without providing a password.
echo 'permit nopass :wheel' | tee /etc/doas.d/wheel.conf

# set the vagrant user password.
echo '${USER}:${PASS}' | chpasswd
EOF

# lock the root account.
chroot /mnt passwd -l root

chroot /mnt ash <<-EOF
set -euxo pipefail 

install -dm 700 ${SSH_DIR}
wget -qO- http://${LOCAL_IP}:${LOCAL_PORT}/${PUBLIC_KEY} | tee ${A_KEYS} >/dev/null
chmod 0600 ${A_KEYS}
chown -R ${USER}:${GROUP} ${SSH_DIR}

ls /etc/ssh/sshd_config

sed -i "s/^#PubkeyAuthentication.*/PubkeyAuthentication yes/; \
s/^#PasswordAuthentication.*/PasswordAuthentication no/; \
s/^#PermitEmptyPasswords.*/PermitEmptyPasswords no/; \
s/^#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/; \
s/^#KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/" ${CFG_SSH}
echo "AllowUsers ${USER}" | tee -a ${CFG_SSH}
EOF

reboot
