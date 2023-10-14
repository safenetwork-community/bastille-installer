#!/bin/ash
set -euxo pipefail

NAME_SH=bootloader.sh
USER_NAME=bas
USER_HOME_DIR=/home/${USER_NAME}

sed -i '\@^/dev/cdrom@d;\@^/dev/fd@d;\@/dev/usbdisk@d' /etc/fstab

# echo "==> ${NAME_SH}: Install the u-root dependencies."
# apk add direnv go

# echo "==> ${NAME_SH}: Install the goenv."
# doas -u ${USER_NAME} wget -q https://github.com/ankitcharolia/goenv/releases/latest/download/goenv-linux-amd64.tar.gz
# doas -u ${USER_NAME} mkdir ./goenv && tar -xzf goenv-linux-amd64.tar.gz -C ./goenv
# doas install -o root -g root ./goenv/goenv /usr/bin/
# ulimit -n 66536
# doas -u ${USER_NAME} goenv --install 1.20.8 &>/dev/null

# echo "==> ${NAME_SH}: Download u-root."
# doas -u ${USER_NAME} git clone https://github.com/u-root/u-root
# cd u-root

# echo "==> ${NAME_SH}: Setup go version.."
# sponge .envrc <<'EOF'
# export GOROOT=~/.go/1.20.8
# EOF

# echo "==> ${NAME_SH}: Install u-root."
# doas -u ${USER_NAME} go build
# doas -u ${USER_NAME} ./u-root core boot
# doas mv /tmp/initramfs.linux_amd64.cpio /boot/initramfs-virt
# cd ${USER_HOME_DIR}
