#!/bin/ash
set -euxo pipefail

NAME_SH=cleanup.sh

echo "==> ${NAME_SH}: Clean up script packages.."
apk del bison build-base efibootmgr flex freetype-dev 
apk del gpg gpg-agent linux-headers python3 rsync unifont

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
