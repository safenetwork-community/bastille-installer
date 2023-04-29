#!/usr/bin/env bash

. /tmp/files/vars.sh

# stop on errors
set -eu

NAME_SH=partition-table-gpt.sh

echo ">>>> ${NAME_SH}: Formatting disk.."
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | gdisk ${DISK}
  o
  y
  n
  1

  +250M
  ef02
  n
  2
   
   
  8304
  p
  w
  y
  q
EOF
