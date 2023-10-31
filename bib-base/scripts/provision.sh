#!/bin/ash
set -euxo pipefail

NAME_SH=provision.sh

# Main user
USER_NAME='bas'
USER_GROUP='bas'
USER_HOME_DIR=/home/${USER_NAME}
ROOT_HOME_DIR=/root
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
apk add build-base cargo curl moreutils rsync

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

echo "==> ${NAME_SH}: Install lunarvim.."
apk add neovim 
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF \
  | LV_BRANCH='release-1.3/neovim-0.9' doas -u ${USER_NAME} \
  curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.3/neovim-0.9/utils/installer/install.sh \
  | doas -u ${USER_NAME} bash
n
n
y
EOF

echo "==> ${NAME_SH}: Install lunarvim on root.."
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF \
  | LV_BRANCH='release-1.3/neovim-0.9' \
  curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.3/neovim-0.9/utils/installer/install.sh \
  | bash
n
n
y
EOF

echo "==> ${NAME_SH}: Disable DNS reverse lookup.."
sed -i -E 's,#?(UseDNS\s+).+,\1no,' /etc/ssh/sshd_config

# NB to get these codes, press ctrl+v then the key combination you want.
echo "==> ${NAME_SH}: Setup bash history navigation.."
sponge /etc/inputrc <<'EOF'
"\e[A": history-search-backward
"\e[B": history-search-forward
set show-all-if-ambiguous on
set completion-ignore-case on
EOF

echo "==> ${NAME_SH}: Setup bash aliases.."
sponge -a ${USER_HOME_DIR}/.profile ${ROOT_HOME_DIR}/.profile <<'EOF'
alias l='ls -lF --color'
alias ll='l -a'
alias h='history 25'
alias j='jobs -l'
alias vim='lvim'
EOF
