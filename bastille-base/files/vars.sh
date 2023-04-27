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
ISCR='manjaro-arm-installer'

PASSWORD=${USER}
PUBLIC_KEY=id_${NAME}.pub
TEMP_PASSWORD=$(/usr/bin/openssl passwd -6 ${USER})

HOME_DIR=/home/${USER}
SSH_DIR=/home/${USER}/.ssh
ROOT_DIR='/mnt'
BOOT_DIR='/mnt/boot/efi'
FILES_DIR='/tmp/files'
ESP_DIR='/boot/efi'

A_KEYS_PATH=${SSH_DIR}/authorized_keys
USER_SUDO_PATH=/etc/sudoers.d/10_${USER}

KEYMAP='us'
LANGUAGE='en_US.UTF-8'
TIMEZONE='UTC'

CONFIG_SCRIPT='/usr/local/bin/arch-config.sh'
ROOT_PARTITION="${DISK}1"
BOOT_PARTITION="${DISK}2"
COUNTRY=${COUNTRY:-BE}
