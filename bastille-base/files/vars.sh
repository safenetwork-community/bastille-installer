#!/usr/bin/env bash

# Drives and partitions

if [[ $PACKER_BUILDER_TYPE == "qemu" ]]; then
  DISK='/dev/vda'
else
  DISK='/dev/sda'
fi
BOOT_DIR='/mnt/boot/efi'
ROOT_DIR='/mnt'
BOOT_LABEL="BOOT"
ROOT_LABEL="ROOT"
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
HOSTNAME_LIVEVM="Artix-liveVM"
KEYMAP_BOX='us'
LANGUAGE_BOX='en_US.UTF-8'
TIMEZONE_BOX='UTC'

# Main user

USERNAME='bas'
GROUPNAME='bas'
USER_PASSWORD=${USERNAME}
TEMP_PASSWORD=$(/usr/bin/openssl passwd -6 ${USERNAME})
USER_PUBLIC_KEY=id_${USERNAME}.pub
USER_HOME_DIR=/home/${USERNAME}
USER_SSH_DIR=/home/${USERNAME}/.ssh
A_KEYS_PATH=${USER_SSH_DIR}/authorized_keys
USER_SUDO_PATH=/etc/sudoers.d/10_${USERNAME}

# Bootloader

ESP_DIR='/boot/efi'
BOOTLOADER_LABEL="ARTIX_BOOT"

# Miscellaneous

FILES_DIR='/tmp/files'
ISCR='manjaro-arm-installer'

CONFIG_SCRIPT='/usr/local/bin/artix-config.sh'
