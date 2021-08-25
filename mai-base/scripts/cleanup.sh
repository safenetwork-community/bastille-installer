#!/usr/bin/bash -x

# Clean the pacman cache.
echo ">>>> cleanup.sh: Cleaning pacman cache.."
/usr/bin/pacman -Sy
/usr/bin/pacman -Scc --noconfirm
