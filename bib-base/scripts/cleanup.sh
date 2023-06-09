#!/usr/bin/bash

. /root/vars.sh

NAME_SH=cleanup.sh

# stop on errors
set -eu

# Clean the pacman cache.
echo "==> ${NAME_SH}: Cleaning pacman cache.."
/usr/bin/pacman -Scc --noconfirm

# Write zeros to improve virtual disk compaction.
if [[ $WRITE_ZEROS == "true" ]]; then
  echo "==> ${NAME_SH}: Writing zeros to improve virtual disk compaction.."
  zerofile=$(/usr/bin/mktemp /zerofile.XXXXX)
  /usr/bin/dd if=/dev/zero of="$zerofile" bs=1M
  /usr/bin/rm -f "$zerofile"
  /usr/bin/sync
fi

echo "==> ${NAME_SH}: Clean up vars.sh"
rm /root/vars.sh

echo "==> ${NAME_SH}: Installation complete!"
/usr/bin/shutdown -h now
