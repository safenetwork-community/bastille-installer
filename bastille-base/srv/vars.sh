#!/usr/bin/env bash

# Host locals

HOST_LIVEVM_NAME="Artix-liveVM"

# Drives and partitions

if [[ $PACKER_BUILDER_TYPE == "qemu" ]]; then
  DISK='/dev/vda'
else
  DISK='/dev/sda'
fi
BOOT_DIR='/mnt/boot/efi'
ROOT_DIR='/mnt'
BOOT_LABEL="AMOHRS_BAZ"
ROOT_LABEL="BWEHT_BAZ"
BOOT_PARTITION="${DISK}1"
ROOT_PARTITION="${DISK}2"
BOOT_SIZE="300M"
ROOT_SIZE="∞"  

# Types

ENCRYPTION_TYPE="none"
FS_TYPE="ext4"
INIT_TYPE="dinit"

# Locals

COUNTRY=${COUNTRY:-BE}
HOSTNAME_BOX="bastille-installer"
KEYMAP_BOX='us'
LANGUAGE_BOX='en_US.UTF-8'
TIMEZONE_BOX='UTC'

# Bastille

ISCR='manjaro-arm-installer'

# Root user

ROOT_PASSWORD='bastille'

# Main user

USER_NAME='bas'
USER_GROUP='bas'
USER_PASSWORD=${USER_NAME}
USER_PUBLIC_KEY=id_${USER_NAME}.pub
USER_HOME_DIR=/home/${USER_NAME}
USER_SSH_DIR=/home/${USER_NAME}/.ssh
USER_KEYS_PATH=${USER_SSH_DIR}/authorized_keys
USER_SUDO_PATH=/etc/sudoers.d/10_${USER_NAME}

# Bootloader

ESP_DIR='/boot/efi'
BOOTLOADER_LABEL="ARTIX_BOOT"

# Other dirs

TMP_FILES_DIR='/tmp/files'
INIT_DIR='/etc/dinit.d'

# Packer scripts

CONFIG_SCRIPT='/usr/local/bin/setup.sh'
