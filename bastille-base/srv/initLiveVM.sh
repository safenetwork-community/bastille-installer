#!/usr/bin/env bash

LOCAL_IP=10.0.2.2
PORT=$1

echo "==> ${NAME_SH}: Downloading vars file.."
curl -Os http://${LOCAL_IP}:${PORT}/vars.sh >/dev/null

. ~/vars.sh

NAME_SH='initLiveVM.sh'

echo "==> ${NAME_SH}: Creating liveVM group.."
/usr/bin/groupadd ${USER_GROUP}
echo "==> ${NAME_SH}: Creating liveVM user.."
/usr/bin/useradd -m -c 'Bas User' -g ${USER_GROUP} -p ${USER_PASSWORD} ${USER_NAME}
tee /etc/sudoers.d/10_${USER_NAME} &>/dev/null <<EOF
Defaults env_keep += "SSH_AUTH_SOCK"
${USER_NAME} ALL=(ALL) NOPASSWD: ALL 
EOF
/usr/bin/chmod 0440 /etc/sudoers.d/10_${USER_NAME}

echo "==> ${NAME_SH}: Creating public key for liveVM SSH connection.."
mkdir -pm 700 ${USER_SSH_DIR}
curl -s http://${LOCAL_IP}:${PORT}/${USER_PUBLIC_KEY} | tee ${USER_KEYS_PATH} >/dev/null
chmod 0600 ${USER_KEYS_PATH}
chown -R ${USER_NAME}:${USER_GROUP} ${USER_SSH_DIR}

echo "==> ${NAME_SH}: Init LiveVM SSH.."
/usr/bin/dinitctl enable sshd
