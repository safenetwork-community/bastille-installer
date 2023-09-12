#!/bin/ash
set -euxo pipefail

NAME_SH=provision.sh

# Main user
USER_NAME='bas'
USER_GROUP='bas'
USER_HOME_DIR=/home/${USER_NAME}
APP_NAME='SE_bastille-installer'
APP_DIR=${USER_HOME_DIR}/${APP_NAME}

echo "==> ${NAME_SH}: Add community repository.."
sed -i 's;\(.*\)main$;\1main\n\1community;' /etc/apk/repositories

echo "==> ${NAME_SH}: Setup autologin.."
sed -i "s@\(^tty[2-9S].*\)@#\1@" /etc/inittab
sed -i "s@^tty1.*@tty1::respawn:/sbin/agetty -a ${USER_NAME} - linux@" /etc/inittab

echo "==> ${NAME_SH}: Upgrading all packages.."
apk upgrade -U --available

echo "==> ${NAME_SH}: Install keyboard layouts.."
apk add kbd-bkeymaps

echo "==> ${NAME_SH}: Add script packages.."
apk add rsync

echo "==> ${NAME_SH}: Merge all system files"
chown root:root -R /tmp/rootdir
rsync -a /tmp/rootdir/* / 

echo "==> ${NAME_SH}: Setup the console keymap (keyboard layout).."
setup-keymap yr yr-af

echo "==> ${NAME_SH}: Install the doas sudo shim.."
apk add doas-sudo-shim

echo "==> ${NAME_SH}: Add support for validating https certificates."
apk add ca-certificates openssl

echo "==> ${NAME_SH}: Install the SE Bastille Installer dependencies."
apk add git bash parted dialog 

echo "==> ${NAME_SH}: Install the SE Bastille Installer."
doas -u ${USER_NAME} git clone https://github.com/safenetwork-community/${APP_NAME}.git
doas -u ${USER_NAME} git -C ${APP_DIR} checkout -q `doas -u ${USER_NAME} git -C ${APP_DIR} describe --tags`

echo "==> ${NAME_SH}: Install neovim.."
apk add neovim

echo "==> ${NAME_SH}: Disable DNS reverse lookup.."
sed -i -E 's,#?(UseDNS\s+).+,\1no,' /etc/ssh/sshd_config

# NB to get these codes, press ctrl+v then the key combination you want.
echo "==> ${NAME_SH}: Setup bash history navigation.."
cat >>/etc/inputrc <<'EOF'
"\e[A": history-search-backward
"\e[B": history-search-forward
set show-all-if-ambiguous on
set completion-ignore-case on
EOF
