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

ROOT_DIR='/mnt'
BOOT_DEVICE='/dev/sda'
ROOTFS=${BOOT_DEVICE}2
APKREPOSOPTS="https://alpine.mirror.wearetriple.com/v3.18/main"

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
USEROPTS="-a ${USER}"
EOF
ERASE_DISKS="${BOOT_DEVICE}" BOOTLOADER="grub" ROOTFS="btrfs" \
setup-alpine -e -f ${PWD}/answers >/dev/null

# add password
passwd -u ${USER}

# mount device
mount -t btrfs ${ROOTFS} ${ROOT_DIR}

# configure the vagrant user.
chroot ${ROOT_DIR} ash <<-EOF
set -euxo pipefail

# configure doas to allow the wheel group members to use root permissions
# without providing a password.
echo 'permit nopass :wheel' | tee /etc/doas.d/wheel.conf

# set the vagrant user password.
echo '${USER}:${PASS}' | chpasswd
EOF

# lock the root account.
chroot ${ROOT_DIR} passwd -l root

chroot ${ROOT_DIR} ash <<-EOF
set -euxo pipefail 

install -dm 700 ${SSH_DIR}
wget -qO- http://${LOCAL_IP}:${LOCAL_PORT}/${PUBLIC_KEY} | tee ${A_KEYS} >/dev/null
chmod 0600 ${A_KEYS}
chown -R ${USER}:${GROUP} ${SSH_DIR}

sed -i "s/^#PubkeyAuthentication.*/PubkeyAuthentication yes/; \
s/^#PasswordAuthentication.*/PasswordAuthentication no/; \
s/^#PermitEmptyPasswords.*/PermitEmptyPasswords no/; \
s/^#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/; \
s/^#KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/" ${CFG_SSH}
echo "AllowUsers ${USER}" | tee -a ${CFG_SSH}
EOF

reboot
