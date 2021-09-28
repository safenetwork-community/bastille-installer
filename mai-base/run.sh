#!/usr/bin/env bash

ISO_URL='iso_url='$(curl -s https://manjaro.org/downloads/official/xfce/ | grep -o "https://.*manjaro-xfce.*minimal.*iso" | tail -1)
ISO_CHECKSUM='iso_checksum='$(curl -s https://manjaro.org/downloads/official/xfce/ | grep "SHA1:" | tail -1 | sed 's/\s//g')

echo $ISO_URL
echo $ISO_CHECKSUM

PACKER_LOG=1 packer build -var $ISO_URL -var $ISO_CHECKSUM manjaro-arm-installer.pkr.hcl
