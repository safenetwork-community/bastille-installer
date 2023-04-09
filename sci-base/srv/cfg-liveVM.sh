#!/usr/bin/env bash

NAME='sci'
USER='sci'
GROUP='sci'
PASSWORD=${USER}
PUBLIC_KEY=id_${NAME}.pub
SSH_DIR=/home/${USER}/.ssh
A_KEYS=${SSH_DIR}/authorized_keys
TEMP_PASSWORD=$(/usr/bin/openssl passwd -6 ${USER})
LOCAL_IP=10.0.2.2
PORT=$1

set -e
set -x

ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime

echo -s ${NAME}'-livevm' | tee /etc/hostname

# /usr/bin/mkinitcpio -p linux

/usr/bin/useradd --password ${TEMP_PASSWORD} --comment 'Sci User' --create-home --user-group ${GROUP}
tee /etc/sudoers.d/10_${USER} &>/dev/null <<EOF
Defaults env_keep += "SSH_AUTH_SOCK"
sci ALL=(ALL) NOPASSWD: ALL 
EOF
/usr/bin/chmod 0440 /etc/sudoers.d/10_${USER}

mkdir -pm 700 ${SSH_DIR}
curl -s http://${LOCAL_IP}:${PORT}/${PUBLIC_KEY} | tee ${A_KEYS} >/dev/null
chmod 0600 ${A_KEYS}
chown -R sci:sci ${SSH_DIR}

mkdir -p /etc/systemd/network
ln -sf /dev/null /etc/systemd/network/99-default.link

/usr/bin/systemctl enable sshd
/usr/bin/systemctl enable dhcpcd

grub-install "$device"
sed -i -e 's/^GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=1/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
