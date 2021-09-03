#!/usr/bin/env bash

# stop on errors
set -e
set -x

if [[ $PACKER_BUILDER_TYPE == "qemu" ]]; then
  DISK='/dev/vda'
else
  DISK='/dev/sda'
fi

FQDN='mai-qemu'
KEYMAP='us'
LANGUAGE='en_US.UTF-8'
TEMP_PASSWORD=$(/usr/bin/openssl passwd -crypt 'temp')
PASSWORD='vagrant'
TIMEZONE='UTC'

CONFIG_SCRIPT='/usr/local/bin/manjaro-config.sh'
ROOT_PARTITION="${DISK}1"
BOOT_PARTITION="${DISK}2"
ROOT_DIR='/mnt'
BOOT_DIR='/mnt/boot'
COUNTRY=${COUNTRY:-BE}

echo ">>>> install-base.sh: Clearing partition table on ${DISK}.."
/usr/bin/sgdisk --zap ${DISK}

echo ">>>> install-base.sh: Destroying magic strings and signatures on ${DISK}.."
/usr/bin/dd if=/dev/zero of=${DISK} bs=512 count=2048
/usr/bin/wipefs --all ${DISK}

echo ">>>> install-base.sh: Formatting disk.."
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

echo ">>>> install-base.sh: Writing Filesystem types.."
mkfs.ext4 -L BOHKS_EQAHM ${ROOT_PARTITION}
mkfs.ext4 ${BOOT_PARTITION}

echo ">>>> install-base.sh: Mounting partitions.."
/usr/bin/mount ${ROOT_PARTITION} ${ROOT_DIR}
/usr/bin/mkdir -p ${BOOT_DIR}
/usr/bin/mount ${BOOT_PARTITION} ${BOOT_DIR}

echo ">>>> install-base.sh: Setting pacman mirrors.."
/usr/bin/pacman-mirrors --fasttrack 5 

echo ">>>> install-base.sh: Bootstrapping the base installation.."
/usr/bin/basestrap ${ROOT_DIR} base linux

echo ">>>> manjaro-base.sh: Updating pacman-mirrors.."
/usr/bin/manjaro-chroot ${ROOT_DIR} pacman-mirrors --fasttrack 5

echo ">>>> install-base.sh: Installing databases.."
/usr/bin/manjaro-chroot ${ROOT_DIR} pacman -Sy

# Need to install netctl as well: https://github.com/archlinux/arch-boxes/issues/70
# Can be removed when Vagrant's Arch plugin will use systemd-networkd: https://github.com/hashicorp/vagrant/pull/11400
echo ">>>> install-base.sh: Installing basic packages.."
/usr/bin/manjaro-chroot ${ROOT_DIR} pacman -S --noconfirm sudo gptfdisk openssh grub dhcpcd netctl manjaro-arm-installer

echo ">>>> install-base.sh: Generating the filesystem table.."
/usr/bin/fstabgen -U ${ROOT_DIR} | tee -a "${ROOT_DIR}/etc/fstab"

echo ">>>> install-base.sh: Configuring grub.."
/usr/bin/manjaro-chroot ${ROOT_DIR} grub-install --force --target=i386-pc --recheck --boot-directory=/boot ${DISK}
/usr/bin/manjaro-chroot ${ROOT_DIR} grub-mkconfig -o /boot/grub/grub.cfg

echo ">>>> manjaro-base.sh: Generating the system configuration script.."
/usr/bin/install --mode=0755 /dev/null "${ROOT_DIR}${CONFIG_SCRIPT}"

CONFIG_SCRIPT_SHORT=`basename "$CONFIG_SCRIPT"`
cat << EOF | tee "${ROOT_DIR}${CONFIG_SCRIPT}"
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Configuring hostname, timezone, and keymap.."
  echo "${FQDN}" | tee /etc/hostname
  /usr/bin/ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
  /usr/bin/hwclock --systohc
  echo "KEYMAP=${KEYMAP}" | tee /etc/vconsole.conf
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Configuring locale.."
  /usr/bin/sed -i "s/#${LANGUAGE}/${LANGUAGE}/" /etc/locale.gen
  /usr/bin/locale-gen
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Creating initramfs.."
  /usr/bin/mkinitcpio -p linux
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Setting root pasword.."
  /usr/bin/usermod --password ${PASSWORD} root
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Configuring network.."
  # Disable systemd Predictable Network Interface Names and revert to traditional interface names
  # https://wiki.archlinux.org/index.php/Network_configuration#Revert_to_traditional_interface_names
  /usr/bin/ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules
  /usr/bin/systemctl enable dhcpcd@eth0.service
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Configuring sshd.."
  /usr/bin/sed -i "s/#UseDNS yes/UseDNS no/" /etc/ssh/sshd_config
  /usr/bin/systemctl enable sshd.service
  # Workaround for https://bugs.archlinux.org/task/58355 which prevents sshd to accept connections after reboot
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Adding workaround for sshd connection issue after reboot.."
  /usr/bin/pacman -S --noconfirm rng-tools
  /usr/bin/systemctl enable rngd
  # Vagrant-specific configuration
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Creating vagrant user.."
  /usr/bin/useradd --password ${TEMP_PASSWORD} --comment "Vagrant User" --create-home --user-group vagrant
  /usr/bin/echo -e "${PASSWORD}\n${PASSWORD}" | /usr/bin/passwd vagrant 
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Configuring sudo.."
  echo "Defaults env_keep += \"SSH_AUTH_SOCK\"" | tee /etc/sudoers.d/10_vagrant
  echo "vagrant ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers.d/10_vagrant
  /usr/bin/chmod 0440 /etc/sudoers.d/10_vagrant
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Configuring ssh access for vagrant.."
  /usr/bin/install --directory --owner=vagrant --group=vagrant --mode=0700 /home/vagrant/.ssh
  /usr/bin/curl --output /home/vagrant/.ssh/authorized_keys --location https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub
  /usr/bin/chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
  /usr/bin/chmod 0600 /home/vagrant/.ssh/authorized_keys 
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Generating ssh keys.."
  /usr/bin/ssh-keygen -A
  echo ">>>> ${CONFIG_SCRIPT_SHORT}: Cleaning up.."
  /usr/bin/pacman -Rcns --noconfirm gptfdisk
EOF

echo ">>>> install-base.sh: Entering chroot and configuring system.."
/usr/bin/manjaro-chroot ${ROOT_DIR} ${CONFIG_SCRIPT}
rm "${ROOT_DIR}${CONFIG_SCRIPT}"

# http://comments.gmane.org/gmane.linux.arch.general/48739
echo ">>>> install-base.sh: Adding workaround for shutdown race condition.."
/usr/bin/install --mode=0644 /root/poweroff.timer "${ROOT_DIR}/etc/systemd/system/poweroff.timer"

echo ">>>> install-base.sh: Completing installation.."
/usr/bin/sleep 3
/usr/bin/umount ${BOOT_DIR}
/usr/bin/umount ${ROOT_DIR}

# Turning network interfaces down to make sure SSH session was dropped on host.
for i in $(/usr/bin/ls -1 /sys/class/net | grep -v "lo"); do /usr/bin/ip link set ${i} down; done

# More info at: https://www.packer.io/docs/provisioners/shell.html#handling-reboots
/usr/bin/systemctl reboot
echo ">>>> install-base.sh: Installation complete!"
