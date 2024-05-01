#!/usr/bin/env bash

# packer environment variabels

TYPE_BUILDER_PACKER=${PACKER_BUILDER_TYPE} 

# Host locals

NAME_LIVEVM_HOST="Artix-liveVM"

# Drives and partitions
if [[ $TYPE_BUILDER_PACKER == "qemu" ]]; then
  DISK='/dev/vda'
 else
   DISK='/dev/sda'
fi
DIR_MNT_BOOT='/mnt/boot'
DIR_MNT_ROOT='/mnt'
LABEL_BOOT="AMOHRS_BAZ"
LABEL_ROOT="BWEHT_BAZ"
PARTITION_BOOT="${DISK}1"
PARTITION_ROOT="${DISK}2"
SIZE_BOOT="300M"
SIZE_ROOT="∞"  

# Types

TYPE_ENCRYPTION="none"
TYPE_FS="btrfs"
TYPE_INIT="dinit"

# Locals

COUNTRY=${COUNTRY:-BE}
HOSTNAME_BOX="bastille-installer"
KEYMAP_BOX='yr-af'
LANGUAGE_BOX='en_US.UTF-8'
TIMEZONE_BOX='UTC'

# Root user

PASSWORD_ROOT='bastij'
DIR_HOME_ROOT=/root

# Main user

GROUP_USER='bas'
NAME_USER='bas'

DIR_HOME_USER=/home/${NAME_USER}
DIR_SSH_USER=/home/${NAME_USER}/.ssh
KEY_PUBLIC_USER=id_${NAME_USER}.pub
PATH_KEYS_USER=${DIR_SSH_USER}/authorized_keys
PATH_SUDO_USER=/etc/sudoers.d/10_${NAME_USER}
PASSWORD_USER=${NAME_USER}

# Bastille

NAME_FILE_APP='SE_bastille-installer'
NAME_TITLE_APP='SE Bastille Installer'
DIR_APP=${DIR_HOME_USER}/${NAME_FILE_APP}

# Bootloader

DIR_BOOT='/boot'
LABEL_BOOTLOADER="ARTIX_BOOT"
NAME_FILE_GOENV="goenv-linux-amd64.tar.gz"
URL_FILE_GOENV="https://github.com/ankitcharolia/goenv/releases/latest/download/${NAME_FILE_GOENV}"

# Other dirs

DIR_FILES_TMP='/tmp/files'
DIR_INIT='/etc/dinit.d'

# Packer scripts
SCRIPT_CONFIG='/usr/local/bin/script.sh'

# script environment variabels

GOENV_ROOT=${DIR_HOME_ROOT}/.go

# Command function
chroot() {
  /usr/bin/artix-chroot ${DIR_MNT_ROOT} $@ 
}

rchroot() {
  sudo -u root /usr/bin/artix-chroot ${DIR_MNT_ROOT} $@ 
}


packer_msg() {
  echo "==> ${NAME_SH}: $@.."
}

packer_msg_exc() {
  echo "==> ${NAME_SH}: $@!"
}

bootstrap() {
  /usr/bin/basestrap ${DIR_MNT_ROOT} $@
}
