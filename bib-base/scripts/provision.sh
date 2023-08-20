#!/bin/ash
set -euxo pipefail

NAME_SH=provision.sh

# Main user
USER_NAME='bas'
USER_GROUP='bas'
USER_HOME_DIR=/home/${USER_NAME}

echo "==> ${NAME_SH}: Add community repository.."
sed -i 's;\(.*\)main$;\1main\n\1community;' /etc/apk/repositories

echo "==> ${NAME_SH}: Setup autologin.."
sed -i "s@\(^tty[2-9S].*\)@#\1@" /etc/inittab
sed -i "s@^tty1.*@tty1::respawn:/sbin/agetty -a ${USER_NAME} - linux@" /etc/inittab

echo "==> ${NAME_SH}: Upgrading all packages.."
apk upgrade -U --available

echo "==> ${NAME_SH}: Add script packages.."
apk add rsync

echo "==> ${NAME_SH}: Merge all system files"
rsync -a /tmp/* / 

echo "==> ${NAME_SH}: Setup the console keymap (keyboard layout).."
setup-keymap us us

echo "==> ${NAME_SH}: Install keyboard layouts.."
apk add kbd-bkeymaps

echo "==> ${NAME_SH}: Install the doas sudo shim.."
apk add doas-sudo-shim

echo "==> ${NAME_SH}: Add support for validating https certificates."
apk add ca-certificates openssl

echo "==> ${NAME_SH}: Install the SE Bastille Installer dependencies."
apk add git bash parted dialog 

echo "==> ${NAME_SH}: Install the SE Bastille Installer."
git clone https://github.com/safenetwork-community/SE_bastille-installer.git
cd SE_bastille-installer; git checkout -q `git describe --tags`; cd ${USER_HOME_DIR}

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

echo "==> ${NAME_SH}: Clean up script packages.."
apk del rsync

# NB prefer discard/trim (safer; faster) over creating a big zero filled file
#    (somewhat unsafe as it has to fill the entire disk, which might trigger
#    a disk (near) full alarm; slower; slightly better compression).
echo "==> ${NAME_SH}: Zero the free disk space for better compression of the box file.."
apk add util-linux
root_dev="$(findmnt -no SOURCE /)"
if [ "$(lsblk -no DISC-GRAN $root_dev | awk '{print $1}')" != '0B' ]; then
    output="$(fstrim -v /)"
    sync && sync && sync && blockdev --flushbufs $root_dev && sleep 15
else
    dd if=/dev/zero of=/EMPTY bs=1M || true && sync && rm -f /EMPTY && sync
fi
