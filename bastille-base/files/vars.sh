#!/usr/bin/env bash

if [[ $PACKER_BUILDER_TYPE == "qemu" ]]; then
  DISK='/dev/vda'
else
  DISK='/dev/sda'
fi

FQDN='bastille-installer'
NAME='bas'
USER='bas'
GROUP='bas'
PASSWORD=${USER}
PUBLIC_KEY=id_${NAME}.pub
SSH_DIR=/home/${USER}/.ssh
A_KEYS=${SSH_DIR}/authorized_keys
TEMP_PASSWORD=$(/usr/bin/openssl passwd -crypt 'temp')

KEYMAP='us'
LANGUAGE='en_US.UTF-8'
TIMEZONE='UTC'

CONFIG_SCRIPT='/usr/local/bin/'${NAME}'-config.sh'
ROOT_PARTITION="${DISK}1"
BOOT_PARTITION="${DISK}2"
ROOT_DIR='/mnt'
BOOT_DIR='/mnt/boot'
COUNTRY=${COUNTRY:-BE}
