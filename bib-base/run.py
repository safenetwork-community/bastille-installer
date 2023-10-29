#!/usr/bin/env python

from pathlib import Path
import subprocess, os

vm_name = "SE_bastille-installer-box"
vm_hv = "qemu"
vm_os = "alpinelinux"
vm_ym = "2023-10"

command = "packer"
subcommand = "build"
option1 = f"-only={vm_name}.{vm_hv}.{vm_os}"

# Environment variables
packer_env = os.environ.copy()
packer_env["PACKER_LOG"] = "1"

# File names
template = f"{vm_name}.pkr.hcl"
vmq_name = f"{vm_name}.qcow2"
vmb_name = f"{vm_name}_{vm_hv}_{vm_os}_{vm_ym}.box"
gcf_name = "grub.cfg"
prv_key_name = "id_folaht_ybgiht"

# Folder locations
path_home         = Path.home()
path_output       = "./output"
path_output_qemu  = f"./output-{vm_os}"
path_virt_manager = "/var/lib/libvirt/images"
path_bibboot      = "./boot"
path_virt_boot    = "/var/lib/libvirt/boot"
path_ssh          = f"{path_home}/.ssh"

# File locations
loc_vmq_old = f"{path_output_qemu}/{vmq_name}"
loc_vmq_new = f"{path_virt_manager}/{vmq_name}"
loc_gcf_old = f"{path_bibboot}/{gcf_name}"
loc_prv_key = f"{path_ssh}/{prv_key_name}"

# delete output folder if it exists
if Path(path_output).is_dir(): 
    subprocess.run(["rm", "-r", path_output])

# delete os output folder if it exists
if Path(path_output_qemu).is_dir(): 
    subprocess.run(["rm", "-r", path_output_qemu])

# Run packer
# args = [command, subcommand, option1, template]
# print(' '.join(args)) 
# subprocess.run(args, env=packer_env)

# Move box to virt-manager 
if Path(path_output).exists() and Path(path_output).is_dir():  
    # subprocess.run(["sudo", "chown", "libvirt-qemu:libvirt-qemu", loc_vmq_old])
    # subprocess.run(["sudo", "chmod", "600", loc_vmq_old])
    # subprocess.run(["sudo", "mv", loc_vmq_old, loc_vmq_new])
    subprocess.run(["sudo", "virt-install", 
                    "--name SE_bastille_installer-box",
                    "--vcpu 2",
                    "--machine q35",
                    "--memory 1024",
                    "--osinfo alpinelinux3.18",
                    "--disk /var/lib/libvirt/images/SE_bastille-installer-box.qcow2,format=qcow2",
                    "--import",
                    "--noautoconsole",
                    "--boot kernel=/var/lib/libvirt/direct_kernel/bzImage," \
                    "initrd=/var/lib/libvirt/direct_kernel/initramfs.linux_amd64.cpio," \
                    "kernel_args=\"root=/dev/vda2 ro console=tty0 console=ttyS0,115200n8d\""
                    ])
    subprocess.run(["scp", 
                    "-i /home/folaht/.ssh/id_bas",
                    "/home/folaht",
                    "bas@`arp-scan --interface=virbr0 --localnet | grep -oP '^[\d]+[.]+[\d.]+'`:~"
                    ])
    subprocess.run(["ssh", 
                    "-i /home/folaht/.ssh/id_bas", 
                    "bas@`arp-scan --interface=virbr0 --localnet | grep -oP '^[\d]+[.]+[\d.]+'`"
                    ])
