#!/usr/bin/env bash

echo 'binnen!'

. /root/vars.sh

NAME_SH=services.sh

# stop on errors
set -eu

echo "==> ${NAME_SH}: Enabling services.."
/usr/bin/dinitctl enable dhcpcd
/usr/bin/dinitctl enable rngd
/usr/bin/dinitctl enable ntpd 
