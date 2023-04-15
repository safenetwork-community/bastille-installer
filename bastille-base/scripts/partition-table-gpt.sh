#!/usr/bin/env bash

. /tmp/files/vars.sh

echo ">>>> partition-table-gpt.sh: Formatting disk.."
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | gdisk ${DISK}
  o
  y
  n
  2

  +250M
  ef02
  n
  1
   
   
  8304
  p
  w
  y
  q
EOF

