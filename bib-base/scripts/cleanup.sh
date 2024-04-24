#!/usr/bin/env bash

NAME_SH=cleanup.sh

packer_msg() {
  echo "==> ${NAME_SH}: $@.."
}

# stop on errors
set -eu


# Clean the pacman cache.
packer_msg "Cleaning pacman cache"
/usr/bin/pacman -Scc --noconfirm >/dev/null

# Write zeros to improve virtual disk compaction.
# if [[ $WRITE_ZEROS == "true" ]]; then
#   packer_msg "Writing zeros to improve virtual disk compaction"
#   zerofile=$(/usr/bin/mktemp /zerofile.XXXXX)
#   /usr/bin/dd if=/dev/zero of="$zerofile" bs=1M >/dev/null
#   /usr/bin/rm -f "$zerofile" >/dev/null
#   /usr/bin/sync >/dev/null
# fi
