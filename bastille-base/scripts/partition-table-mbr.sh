#!/usr/bin/env bash

. /tmp/files/vars.sh

echo ">>>> partition-table-gpt.sh: Formatting disk.."
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${DISK}
  o
  n
  p
  2

  +250M
  n
  p
  1
   
   
  a
  1
  p
  w
  q
EOF

