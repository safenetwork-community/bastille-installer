#!/usr/bin/env bash

TEMP_PASSWORD=$(/usr/bin/openssl passwd -crypt 'temp')
PASSWORD='vagrant'

# Vagrant-specific configuration
/usr/bin/useradd --password ${TEMP_PASSWORD} --comment 'Vagrant User' --create-home --user-group vagrant
echo -e "${PASSWORD}\n${PASSWORD}" | /usr/bin/passwd vagrant
echo 'Defaults env_keep += "SSH_AUTH_SOCK"' | tee /etc/sudoers.d/10_vagrant
echo 'vagrant ALL=(ALL) NOPASSWD: ALL' | tee -a /etc/sudoers.d/10_vagrant
/usr/bin/chmod 0440 /etc/sudoers.d/10_vagrant
/usr/bin/systemctl start sshd.service
