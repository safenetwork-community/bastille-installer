#!/usr/bin/sh -x

. /tmp/files/vars.sh

# Clean the pacman cache.
echo ">>>> cleanup.sh: Cleaning pacman cache.."
/usr/bin/pacman -Scc --noconfirm

echo ">>>> cleanup.sh: Removing srv files"  
rm ${ISO_ROOT_DIR}/.ssh/authorized_keys
rm ${ISO_ROOT_DIR}/id_sci.pub
rm ${ISO_ROOT_DIR}/vars.sh
