#!/usr/bin/env bash

NAME='bas'
USER='bas'
GROUP='bas'
PASSWORD=${USER}
PUBLIC_KEY=id_${NAME}.pub
SSH_DIR=/home/${USER}/.ssh
A_KEYS=${SSH_DIR}/authorized_keys
TEMP_PASSWORD=$(/usr/bin/openssl passwd -6 ${USER})
LOCAL_IP=10.0.2.2
PORT=$1

NAME_SH='cfg-liveVM.sh'

echo ">>>> ${NAME_SH}: Modifying local settings liveVM.."
ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime
echo -s ${NAME}'-livevm' | tee /etc/hostname >/edv/null


echo ">>>> ${NAME_SH}: Creating liveVM user.."
/usr/bin/useradd --password ${TEMP_PASSWORD} --comment 'Bas User' --create-home --user-group ${GROUP}
tee /etc/sudoers.d/10_${USER} &>/dev/null <<EOF
Defaults env_keep += "SSH_AUTH_SOCK"
${USER} ALL=(ALL) NOPASSWD: ALL 
EOF
/usr/bin/chmod 0440 /etc/sudoers.d/10_${USER}

echo ">>>> ${NAME_SH}: Creating public key for liveVM SSH connection.."
mkdir -pm 700 ${SSH_DIR}
curl -s http://${LOCAL_IP}:${PORT}/${PUBLIC_KEY} | tee ${A_KEYS} >/dev/null
chmod 0600 ${A_KEYS}
chown -R ${USER}:${GROUP} ${SSH_DIR}

echo ">>>> ${NAME_SH}: Rebooting liveVM.."
/usr/bin/systemctl start sshd.service
